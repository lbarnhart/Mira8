import Foundation
import AuthenticationServices
import UIKit

enum InstacartServiceError: LocalizedError {
    case configurationMissing
    case authenticationFailed
    case invalidCallback
    case tokenExchangeFailed
    case tokenRefreshFailed
    case notAuthenticated
    case invalidResponse
    case network(statusCode: Int)
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Instacart credentials are not configured. Add valid values to Configuration.plist."
        case .authenticationFailed:
            return "Unable to authenticate with Instacart. Please try again."
        case .invalidCallback:
            return "Instacart returned an unexpected authorization response."
        case .tokenExchangeFailed:
            return "Failed to exchange the authorization code for tokens."
        case .tokenRefreshFailed:
            return "Session expired and refresh attempt failed."
        case .notAuthenticated:
            return "Please connect your Instacart account to continue."
        case .invalidResponse:
            return "Instacart returned an unexpected response."
        case .network(let statusCode):
            return "Instacart request failed (status code: \(statusCode))."
        case .productNotFound:
            return "Product not available on Instacart at the moment."
        }
    }
}

actor InstacartService {
    static let shared = InstacartService()

    private enum KeychainKeys {
        static let authToken = "instacart.auth.token"
    }

    private let keychain = KeychainHelper.shared
    private var authToken: InstacartAuthToken?
    private var cachedCartCount: (value: Int, timestamp: Date)?
    private var lastRequestDate: Date?

    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let presentationProvider = AuthenticationPresentationProvider()
    private var authSession: ASWebAuthenticationSession?

    private let minimumRequestInterval: TimeInterval = 1.0
    private let cartCacheDuration: TimeInterval = 30.0

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = true
        urlSession = URLSession(configuration: configuration)

        jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .iso8601

        jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        jsonEncoder.dateEncodingStrategy = .iso8601

        if let data = try? keychain.data(for: KeychainKeys.authToken),
           let stored = try? jsonDecoder.decode(InstacartAuthToken.self, from: data) {
            authToken = stored
        }
    }

    // MARK: - Authentication

    func authenticate() async throws -> Bool {
        guard configurationIsValid() else { throw InstacartServiceError.configurationMissing }
        if isAuthenticated() { return true }

        let state = UUID().uuidString
        guard let authURL = authorizationURL(state: state) else {
            throw InstacartServiceError.configurationMissing
        }

        let callbackScheme = URL(string: Constants.Instacart.redirectURI)?.scheme

        return try await withCheckedThrowingContinuation { continuation in
            startAuthSession(url: authURL, callbackScheme: callbackScheme, state: state, continuation: continuation)
        }
    }

    func isAuthenticated() -> Bool {
        guard let token = authToken else { return false }
        return !token.isExpired
    }

    func logout() {
        authToken = nil
        cachedCartCount = nil
        try? keychain.delete(KeychainKeys.authToken)
    }

    // MARK: - Catalog & Cart

    func searchProduct(upc: String?, name: String, brand: String) async throws -> InstacartProduct? {
        let accessToken = try await validAccessToken()
        try await applyRateLimiting()

        guard let url = searchURL(upc: upc, name: name, brand: brand) else {
            throw InstacartServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstacartServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            let searchResponse = try jsonDecoder.decode(InstacartSearchResponse.self, from: data)
            return searchResponse.products.first(where: { $0.available }) ?? searchResponse.products.first
        case 404:
            return nil
        default:
            throw InstacartServiceError.network(statusCode: httpResponse.statusCode)
        }
    }

    func addToCart(product: InstacartProduct) async throws -> Bool {
        let accessToken = try await validAccessToken()
        try await applyRateLimiting()

        guard let url = URL(string: "\(Constants.Instacart.apiBaseURL)/carts/current/items") else {
            throw InstacartServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "product_id": product.id,
            "quantity": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (_, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstacartServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 404 {
                throw InstacartServiceError.productNotFound
            }
            throw InstacartServiceError.network(statusCode: httpResponse.statusCode)
        }

        if let cached = cachedCartCount {
            cachedCartCount = (cached.value + 1, Date())
        }

        return true
    }

    func getCartItemCount() async throws -> Int {
        if let cache = cachedCartCount, Date().timeIntervalSince(cache.timestamp) < cartCacheDuration {
            return cache.value
        }

        let accessToken = try await validAccessToken()
        try await applyRateLimiting()

        guard let url = URL(string: "\(Constants.Instacart.apiBaseURL)/carts/current") else {
            throw InstacartServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstacartServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw InstacartServiceError.network(statusCode: httpResponse.statusCode)
        }

        let cartResponse = try jsonDecoder.decode(InstacartCartResponse.self, from: data)
        let count = cartResponse.items.reduce(0) { $0 + $1.quantity }
        cachedCartCount = (count, Date())
        return count
    }

    // MARK: - Token helpers

    private func validAccessToken() async throws -> String {
        if let token = authToken {
            if token.shouldRefresh {
                try await refreshToken()
            }
            guard let refreshed = authToken, !refreshed.isExpired else {
                throw InstacartServiceError.notAuthenticated
            }
            return refreshed.accessToken
        }

        if let data = try? keychain.data(for: KeychainKeys.authToken),
           let stored = try? jsonDecoder.decode(InstacartAuthToken.self, from: data) {
            authToken = stored
            if stored.shouldRefresh {
                try await refreshToken()
            }
            guard let refreshed = authToken, !refreshed.isExpired else {
                throw InstacartServiceError.notAuthenticated
            }
            return refreshed.accessToken
        }

        throw InstacartServiceError.notAuthenticated
    }

    private func refreshToken() async throws {
        guard let refreshToken = authToken?.refreshToken else {
            throw InstacartServiceError.notAuthenticated
        }

        guard let url = URL(string: Constants.Instacart.tokenURL) else {
            throw InstacartServiceError.configurationMissing
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Constants.Instacart.clientID,
            "client_secret": Constants.Instacart.clientSecret
        ]
        request.httpBody = body.percentEncoded()

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstacartServiceError.tokenRefreshFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw InstacartServiceError.tokenRefreshFailed
        }

        let tokenResponse = try jsonDecoder.decode(InstacartTokenResponse.self, from: data)
        let newToken = tokenResponse.toAuthToken()
        try store(token: newToken)
    }

    private func store(token: InstacartAuthToken) throws {
        let data = try jsonEncoder.encode(token)
        try keychain.set(data, for: KeychainKeys.authToken)
        authToken = token
        cachedCartCount = nil
    }

    // MARK: - OAuth helpers

    private func startAuthSession(
        url: URL,
        callbackScheme: String?,
        state: String,
        continuation: CheckedContinuation<Bool, Error>
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self else {
                continuation.resume(throwing: InstacartServiceError.authenticationFailed)
                return
            }

            Task {
                await self.handleAuthCompletion(
                    callbackURL: callbackURL,
                    error: error,
                    expectedState: state,
                    continuation: continuation
                )
            }
        }

        authSession = session

        let provider = presentationProvider

        Task { [weak self] in
            guard let self else { return }
            let didStart = await MainActor.run { () -> Bool in
                session.prefersEphemeralWebBrowserSession = true
                session.presentationContextProvider = provider
                return session.start()
            }
            if !didStart {
                await self.handleAuthSessionStartFailure(continuation: continuation)
            }
        }
    }

    private func handleAuthSessionStartFailure(continuation: CheckedContinuation<Bool, Error>) {
        continuation.resume(throwing: InstacartServiceError.authenticationFailed)
        authSession = nil
    }

    private func handleAuthCompletion(
        callbackURL: URL?,
        error: Error?,
        expectedState: String,
        continuation: CheckedContinuation<Bool, Error>
    ) async {
        defer { authSession = nil }

        if let error = error {
            continuation.resume(throwing: error)
            return
        }

        guard let callbackURL,
              let code = authorizationCode(from: callbackURL, expectedState: expectedState) else {
            continuation.resume(throwing: InstacartServiceError.invalidCallback)
            return
        }

        do {
            try await exchangeAuthorizationCode(code: code)
            continuation.resume(returning: true)
        } catch {
            continuation.resume(throwing: error)
        }
    }

    private func exchangeAuthorizationCode(code: String) async throws {
        guard let tokenURL = URL(string: Constants.Instacart.tokenURL) else {
            throw InstacartServiceError.configurationMissing
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Constants.Instacart.redirectURI,
            "client_id": Constants.Instacart.clientID,
            "client_secret": Constants.Instacart.clientSecret
        ]
        request.httpBody = body.percentEncoded()

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstacartServiceError.tokenExchangeFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw InstacartServiceError.tokenExchangeFailed
        }

        let tokenResponse = try jsonDecoder.decode(InstacartTokenResponse.self, from: data)
        let authToken = tokenResponse.toAuthToken()
        try store(token: authToken)
    }

    private func authorizationURL(state: String) -> URL? {
        var components = URLComponents(string: Constants.Instacart.authorizationURL)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Constants.Instacart.clientID),
            URLQueryItem(name: "redirect_uri", value: Constants.Instacart.redirectURI),
            URLQueryItem(name: "scope", value: "carts.read carts.write catalog.read"),
            URLQueryItem(name: "state", value: state)
        ]
        return components?.url
    }

    private func authorizationCode(from url: URL, expectedState: String) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }
        let state = items.first(where: { $0.name == "state" })?.value
        guard state == expectedState else { return nil }
        return items.first(where: { $0.name == "code" })?.value
    }

    static func hasValidConfiguration() -> Bool {
        !Constants.Instacart.clientID.isEmpty &&
        !Constants.Instacart.clientSecret.isEmpty
    }

    private func configurationIsValid() -> Bool {
        Self.hasValidConfiguration()
    }

    // MARK: - Request utilities

    private func applyRateLimiting() async throws {
        if let lastRequestDate {
            let delta = Date().timeIntervalSince(lastRequestDate)
            if delta < minimumRequestInterval {
                let delay = minimumRequestInterval - delta
                let nanoseconds = UInt64(max(delay, 0) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
            }
        }
        lastRequestDate = Date()
    }

    private func searchURL(upc: String?, name: String, brand: String) -> URL? {
        // TODO: Confirm search endpoint path/parameters against Instacart Connect documentation.
        var components = URLComponents(string: "\(Constants.Instacart.apiBaseURL)/catalog/products/search")
        var queryItems: [URLQueryItem] = []

        if let upc = upc, !upc.isEmpty {
            queryItems.append(URLQueryItem(name: "upc", value: upc))
        }

        let compoundQuery = [brand, name]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !compoundQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: compoundQuery))
        }

        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }
}

private final class AuthenticationPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }
}

private extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data? {
        let query = map { key, value -> String in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
        return query.data(using: .utf8)
    }
}
