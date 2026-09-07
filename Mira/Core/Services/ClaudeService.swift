import Foundation

// MARK: - Claude Service
/// Shared service for all Claude AI API interactions.
/// Use this service for ingredient analysis, dietary detection, and other AI features.
actor ClaudeService {
    static let shared = ClaudeService()

    private let apiClient: APIClient
    private let cache: ClaudeResponseCache

    init(apiClient: APIClient = APIClient(), cache: ClaudeResponseCache = ClaudeResponseCache()) {
        self.apiClient = apiClient
        self.cache = cache
    }

    // MARK: - Configuration Check

    var isConfigured: Bool {
        !Constants.Claude.apiKey.isEmpty
    }

    // MARK: - Simple Text Completion

    /// Send a simple text prompt and get a text response.
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - systemPrompt: Optional system prompt to set context
    ///   - model: The Claude model to use (defaults to Haiku for cost efficiency)
    ///   - maxTokens: Maximum tokens in the response
    ///   - cacheKey: Optional key for caching the response
    /// - Returns: The text response from Claude
    func complete(
        prompt: String,
        systemPrompt: String? = nil,
        model: ClaudeModel = .haiku,
        maxTokens: Int = Constants.Claude.maxTokensDefault,
        cacheKey: String? = nil
    ) async throws -> String {
        // Check cache first
        if let cacheKey = cacheKey, let cached = await cache.get(key: cacheKey) {
            AppLog.debug("Claude cache hit for key: \(cacheKey)", category: .network)
            return cached
        }

        guard isConfigured else {
            throw ClaudeError.notConfigured
        }

        let request = ClaudeRequest(
            model: model.modelId,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: [ClaudeMessage(role: .user, text: prompt)]
        )

        let response: ClaudeResponse = try await apiClient.request(ClaudeEndpoint.messages(request))

        guard let text = response.content.first?.text else {
            throw ClaudeError.emptyResponse
        }

        // Cache the response
        if let cacheKey = cacheKey {
            await cache.set(key: cacheKey, value: text)
        }

        if let usage = response.usage {
            AppLog.debug("Claude API usage - Input: \(usage.inputTokens), Output: \(usage.outputTokens)", category: .network)
        }

        return text
    }

    // MARK: - JSON Completion

    /// Send a prompt and parse the response as JSON.
    /// - Parameters:
    ///   - prompt: The user's prompt (should request JSON output)
    ///   - systemPrompt: Optional system prompt
    ///   - model: The Claude model to use
    ///   - maxTokens: Maximum tokens in the response
    ///   - cacheKey: Optional cache key
    /// - Returns: Decoded response of type T
    func completeJSON<T: Codable>(
        prompt: String,
        systemPrompt: String? = nil,
        model: ClaudeModel = .haiku,
        maxTokens: Int = Constants.Claude.maxTokensDefault,
        cacheKey: String? = nil
    ) async throws -> T {
        let text = try await complete(
            prompt: prompt,
            systemPrompt: systemPrompt,
            model: model,
            maxTokens: maxTokens,
            cacheKey: cacheKey
        )

        // Extract JSON from response (handle markdown code blocks)
        let jsonString = extractJSON(from: text)

        guard let data = jsonString.data(using: .utf8) else {
            throw ClaudeError.invalidJSON
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLog.error("Failed to decode Claude JSON response: \(error)", category: .network)
            throw ClaudeError.decodingFailed(error)
        }
    }

    // MARK: - Helpers

    /// Extract JSON from a response that may contain markdown code blocks.
    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code block
        if let jsonMatch = text.range(of: "```json\\s*([\\s\\S]*?)```", options: .regularExpression) {
            let jsonContent = text[jsonMatch]
            let cleaned = jsonContent
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned
        }

        // Try generic code block
        if let codeMatch = text.range(of: "```\\s*([\\s\\S]*?)```", options: .regularExpression) {
            let codeContent = text[codeMatch]
            let cleaned = codeContent
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned
        }

        // Return as-is if no code block found
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Claude Models
enum ClaudeModel {
    case haiku
    case sonnet

    var modelId: String {
        switch self {
        case .haiku:
            return Constants.Claude.defaultModel
        case .sonnet:
            return Constants.Claude.sonnetModel
        }
    }
}

// MARK: - Claude Errors
enum ClaudeError: LocalizedError {
    case notConfigured
    case emptyResponse
    case invalidJSON
    case decodingFailed(Error)
    case rateLimited
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Claude API key is not configured. Please add your API key to Configuration.plist."
        case .emptyResponse:
            return "Claude returned an empty response."
        case .invalidJSON:
            return "Failed to parse JSON from Claude response."
        case .decodingFailed(let error):
            return "Failed to decode Claude response: \(error.localizedDescription)"
        case .rateLimited:
            return "Claude API rate limit reached. Please try again in a moment."
        case .serverError(let message):
            return "Claude API error: \(message)"
        }
    }
}

// MARK: - Response Cache
actor ClaudeResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let maxAge: TimeInterval = 60 * 60 * 24 * 7 // 7 days

    struct CachedResponse {
        let value: String
        let cachedAt: Date
    }

    func get(key: String) -> String? {
        guard let cached = cache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(cached.cachedAt) > maxAge {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.value
    }

    func set(key: String, value: String) {
        cache[key] = CachedResponse(value: value, cachedAt: Date())

        // Prune old entries if cache is getting large
        if cache.count > 500 {
            pruneExpired()
        }
    }

    private func pruneExpired() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.cachedAt) <= maxAge }
    }

    func clear() {
        cache.removeAll()
    }
}
