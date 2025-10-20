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

// MARK: - Generic API Client
actor APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger: NetworkLogger

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        enableLogging: Bool = true
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.logger = NetworkLogger(isEnabled: enableLogging)

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
        let request = try buildURLRequest(from: endpoint)
        await logger.logRequest(request)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            await logger.logResponse(response: httpResponse, data: data)

            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.httpError(from: httpResponse.statusCode)
            }

            return data
        } catch {
            let networkError = NetworkError.from(error)
            await logger.logError(networkError)
            throw networkError
        }
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
        AppLog.debug("   URL: \(request.url?.absoluteString ?? "Unknown")", category: .network)
        AppLog.debug("   Method: \(request.httpMethod ?? "Unknown")", category: .network)

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            AppLog.debug("   Headers: \(headers)", category: .network)
        }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            AppLog.debug("   Body: \(bodyString)", category: .network)
        }

        AppLog.debug("---", category: .network)
    }

    func logResponse(response: HTTPURLResponse, data: Data) {
        guard isEnabled else { return }

        AppLog.debug("📡 API Response:", category: .network)
        AppLog.debug("   Status: \(response.statusCode)", category: .network)
        AppLog.debug("   URL: \(response.url?.absoluteString ?? "Unknown")", category: .network)

        if let responseString = String(data: data, encoding: .utf8) {
            let truncated = responseString.count > 1000
                ? String(responseString.prefix(1000)) + "... (truncated)"
                : responseString
            AppLog.debug("   Data: \(truncated)", category: .network)
        }

        AppLog.debug("---", category: .network)
    }

    func logResponse<T>(data: Data, type: T.Type) {
        guard isEnabled else { return }

        AppLog.debug("✅ Decoded to: \(type)", category: .network)
        AppLog.debug("---", category: .network)
    }

    func logError(_ error: Error) {
        guard isEnabled else { return }

        AppLog.error("❌ API Error: \(error.localizedDescription)", category: .network)
        AppLog.debug("---", category: .network)
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
        var mutableEndpoint = endpoint
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
