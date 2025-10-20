import Foundation

// MARK: - Network Error Types
enum NetworkError: LocalizedError {
    case noInternet
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)
    case productNotFound
    case invalidURL
    case invalidRequest
    case timeout
    case rateLimited
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection available. Please check your network settings and try again."
        case .invalidResponse:
            return "Invalid response received from server. Please try again later."
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error occurred (HTTP \(statusCode)). Please try again later."
        case .productNotFound:
            return "Product not found. The barcode may not be in our database."
        case .invalidURL:
            return "Invalid URL configuration. Please contact support."
        case .invalidRequest:
            return "Invalid request format. Please try again."
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .rateLimited:
            return "We're receiving a lot of traffic right now. Please try again in a moment."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var failureReason: String? {
        switch self {
        case .noInternet:
            return "Device is not connected to the internet"
        case .invalidResponse:
            return "Server returned malformed data"
        case .decodingError:
            return "JSON parsing failed"
        case .serverError(let statusCode):
            return "HTTP status code \(statusCode)"
        case .productNotFound:
            return "Barcode not found in database"
        case .invalidURL:
            return "Malformed URL"
        case .invalidRequest:
            return "Request validation failed"
        case .timeout:
            return "Network request exceeded timeout limit"
        case .rateLimited:
            return "API rate limit reached"
        case .unknown:
            return "Unhandled error condition"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Connect to Wi-Fi or cellular data and try again"
        case .invalidResponse, .serverError:
            return "Wait a moment and try again, or contact support if the problem persists"
        case .decodingError:
            return "This may be a temporary issue. Please try again"
        case .productNotFound:
            return "Try scanning the barcode again or search manually"
        case .invalidURL, .invalidRequest:
            return "Please contact support for assistance"
        case .timeout:
            return "Check your internet connection and try again"
        case .rateLimited:
            return "Wait a few seconds and try again"
        case .unknown:
            return "Please try again or contact support if the issue continues"
        }
    }
}

// MARK: - Network Error Extensions
extension NetworkError {
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternet
            case .timedOut:
                return .timeout
            case .badURL:
                return .invalidURL
            case .badServerResponse:
                return .invalidResponse
            case .resourceUnavailable:
                return .rateLimited
            default:
                return .unknown(urlError)
            }
        }

        if error is DecodingError {
            return .decodingError(error)
        }

        return .unknown(error)
    }

    static func httpError(from statusCode: Int) -> NetworkError {
        switch statusCode {
        case 404:
            return .productNotFound
        case 429:
            return .rateLimited
        case 400...499:
            return .invalidRequest
        case 500...599:
            return .serverError(statusCode)
        default:
            return .serverError(statusCode)
        }
    }
}

// MARK: - API Response Error
struct APIErrorResponse: Codable, Error {
    let message: String
    let code: String?
    let statusCode: Int?

    init(message: String, code: String? = nil, statusCode: Int? = nil) {
        self.message = message
        self.code = code
        self.statusCode = statusCode
    }
}

// MARK: - Network Result Type
typealias NetworkResult<T> = Result<T, NetworkError>
