import Foundation

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func requestData(_ endpoint: APIEndpoint) async throws -> Data
}

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var timeout: TimeInterval { get }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Retry Configuration
struct RetryConfiguration {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>

    static let `default` = RetryConfiguration(
        maxRetries: 3,
        baseDelay: 0.5,
        maxDelay: 8.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    static let none = RetryConfiguration(
        maxRetries: 0,
        baseDelay: 0,
        maxDelay: 0,
        retryableStatusCodes: []
    )

    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.3) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
}

// MARK: - Generic API Client
actor APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger: NetworkLogger
    private let retryConfig: RetryConfiguration

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        enableLogging: Bool = true,
        retryConfiguration: RetryConfiguration = .default
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.logger = NetworkLogger(isEnabled: enableLogging)
        self.retryConfig = retryConfiguration

        // Configure decoder for common date formats
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Configure encoder
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Generic Request Method
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await requestData(endpoint)

        do {
            let result = try decoder.decode(T.self, from: data)
            await logger.logResponse(data: data, type: T.self)
            return result
        } catch {
            await logger.logError(error)
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Raw Data Request
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        return try await requestDataWithRetry(endpoint, attempt: 0)
    }

    private func requestDataWithRetry(_ endpoint: APIEndpoint, attempt: Int) async throws -> Data {
        let request = try buildURLRequest(from: endpoint)

        if attempt == 0 {
            await logger.logRequest(request)
        } else {
            await logger.logRetry(attempt: attempt, maxRetries: retryConfig.maxRetries)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            await logger.logResponse(response: httpResponse, data: data)

            // Check for retryable status codes
            if retryConfig.retryableStatusCodes.contains(httpResponse.statusCode) && attempt < retryConfig.maxRetries {
                let delay = retryConfig.delay(for: attempt)
                AppLog.debug("Retryable status \(httpResponse.statusCode), waiting \(String(format: "%.2f", delay))s before retry", category: .network)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await requestDataWithRetry(endpoint, attempt: attempt + 1)
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.httpError(from: httpResponse.statusCode)
            }

            return data
        } catch let error as NetworkError {
            // Don't retry NetworkError types that aren't transient
            await logger.logError(error)
            throw error
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }

            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw CancellationError()
            }

            // Retry on transient errors (timeout, connection lost, etc.)
            if isRetryableError(error) && attempt < retryConfig.maxRetries {
                let delay = retryConfig.delay(for: attempt)
                AppLog.debug("Transient error: \(error.localizedDescription), waiting \(String(format: "%.2f", delay))s before retry", category: .network)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await requestDataWithRetry(endpoint, attempt: attempt + 1)
            }

            let networkError = NetworkError.from(error)
            await logger.logError(networkError)
            throw networkError
        }
    }

    private func isRetryableError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let retryableCodes: Set<Int> = [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed
        ]
        return nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code)
    }

    // MARK: - Request Building
    private func buildURLRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = buildURL(from: endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: endpoint.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func buildURL(from endpoint: APIEndpoint) -> URL? {
        guard var components = URLComponents(string: endpoint.baseURL + endpoint.path) else {
            return nil
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }
}

// MARK: - Network Logger
actor NetworkLogger {
    private let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        AppLog.debug("🌐 API Request:", category: .network)
        AppLog.debug("   URL: \(redactedURL(request.url))", category: .network)
        AppLog.debug("   Method: \(request.httpMethod ?? "Unknown")", category: .network)

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            AppLog.debug("   Headers: \(redactedHeaders(headers))", category: .network)
        }

        if let body = request.httpBody {
            AppLog.debug("   Body: \(body.count) bytes", category: .network)
        }

        AppLog.debug("---", category: .network)
    }

    func logResponse(response: HTTPURLResponse, data: Data) {
        guard isEnabled else { return }

        AppLog.debug("📡 API Response:", category: .network)
        AppLog.debug("   Status: \(response.statusCode)", category: .network)
        AppLog.debug("   URL: \(redactedURL(response.url))", category: .network)
        AppLog.debug("   Data: \(data.count) bytes", category: .network)

        AppLog.debug("---", category: .network)
    }

    func logResponse<T>(data: Data, type: T.Type) {
        guard isEnabled else { return }

        AppLog.debug("✅ Decoded to: \(type)", category: .network)
        AppLog.debug("---", category: .network)
    }

    func logError(_ error: Error) {
        guard isEnabled else { return }

        AppLog.error("API Error: \(error.localizedDescription)", category: .network)
        AppLog.debug("---", category: .network)
    }

    func logRetry(attempt: Int, maxRetries: Int) {
        guard isEnabled else { return }

        AppLog.debug("Retry attempt \(attempt)/\(maxRetries)", category: .network)
    }

    private func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        let sensitiveNames = ["authorization", "cookie", "set-cookie", "x-api-key"]
        return headers.reduce(into: [:]) { result, entry in
            result[entry.key] = sensitiveNames.contains(entry.key.lowercased()) ? "<redacted>" : entry.value
        }
    }

    private func redactedURL(_ url: URL?) -> String {
        guard let url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "Unknown"
        }

        let sensitiveNames = ["api_key", "apikey", "key", "token", "access_token"]
        components.queryItems = components.queryItems?.map { item in
            sensitiveNames.contains(item.name.lowercased())
                ? URLQueryItem(name: item.name, value: "<redacted>")
                : item
        }
        return components.string ?? "Unknown"
    }
}

// MARK: - Convenience Extensions
extension APIClient {
    // MARK: - GET Requests
    func get<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        return try await request(endpoint)
    }

    func getData(_ endpoint: APIEndpoint) async throws -> Data {
        return try await requestData(endpoint)
    }

    // MARK: - POST Requests
    func post<T: Codable, Body: Codable>(_ endpoint: APIEndpoint, body: Body) async throws -> T {
        let mutableEndpoint = endpoint
        do {
            let bodyData = try encoder.encode(body)
            return try await request(ModifiedEndpoint(endpoint: mutableEndpoint, body: bodyData))
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - Modified Endpoint Helper
private struct ModifiedEndpoint: APIEndpoint {
    let baseURL: String
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let queryItems: [URLQueryItem]?
    let body: Data?
    let timeout: TimeInterval

    init(endpoint: APIEndpoint, body: Data? = nil) {
        self.baseURL = endpoint.baseURL
        self.path = endpoint.path
        self.method = endpoint.method
        self.headers = endpoint.headers
        self.queryItems = endpoint.queryItems
        self.body = body
        self.timeout = endpoint.timeout
    }
}

// MARK: - Default Endpoint Implementation
extension APIEndpoint {
    var method: HTTPMethod { .GET }
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var timeout: TimeInterval { 30.0 }
}
