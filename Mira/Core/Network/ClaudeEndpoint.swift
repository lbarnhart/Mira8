import Foundation

// MARK: - Claude API Endpoint
enum ClaudeEndpoint: APIEndpoint {
    case messages(ClaudeRequest)

    var baseURL: String {
        Constants.Claude.baseURL
    }

    var path: String {
        switch self {
        case .messages:
            return Constants.Claude.messagesPath
        }
    }

    var method: HTTPMethod {
        switch self {
        case .messages:
            return .POST
        }
    }

    var headers: [String: String]? {
        [
            "x-api-key": Constants.Claude.apiKey,
            "anthropic-version": Constants.Claude.apiVersion,
            "Content-Type": "application/json"
        ]
    }

    var queryItems: [URLQueryItem]? {
        nil
    }

    var body: Data? {
        switch self {
        case .messages(let request):
            return try? JSONEncoder().encode(request)
        }
    }

    var timeout: TimeInterval {
        Constants.Claude.requestTimeout
    }
}

// MARK: - Claude Request Models
struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let system: String?
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }

    init(
        model: String = Constants.Claude.defaultModel,
        maxTokens: Int = Constants.Claude.maxTokensDefault,
        system: String? = nil,
        messages: [ClaudeMessage]
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
    }
}

struct ClaudeMessage: Codable {
    let role: ClaudeRole
    let content: [ClaudeContent]

    init(role: ClaudeRole, text: String) {
        self.role = role
        self.content = [.text(text)]
    }

}

enum ClaudeRole: String, Codable {
    case user
    case assistant
}

enum ClaudeContent: Codable {
    case text(String)

    enum CodingKeys: String, CodingKey {
        case type
        case text
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
        }
    }
}

// MARK: - Claude Response Models
struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeResponseContent]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct ClaudeResponseContent: Codable {
    let type: String
    let text: String?
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    // CodingKeys removed - APIClient's .convertFromSnakeCase handles this automatically
}

// MARK: - Claude Error Response
struct ClaudeErrorResponse: Codable, Error {
    let type: String
    let error: ClaudeErrorDetail
}

struct ClaudeErrorDetail: Codable {
    let type: String
    let message: String
}
