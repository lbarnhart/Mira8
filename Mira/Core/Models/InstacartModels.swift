import Foundation

struct InstacartProduct: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let price: Double?
    let imageURL: String?
    let available: Bool
}

struct InstacartAuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt
    }

    var shouldRefresh: Bool {
        Date().addingTimeInterval(300) >= expiresAt
    }
}

struct InstacartTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let scope: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }

    func toAuthToken(referenceDate: Date = Date()) -> InstacartAuthToken {
        InstacartAuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: referenceDate.addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}

struct InstacartSearchResponse: Codable {
    let products: [InstacartProduct]
}

struct InstacartCartResponse: Codable {
    let id: String
    let items: [InstacartCartItem]

    struct InstacartCartItem: Codable {
        let id: String
        let quantity: Int
    }
}
