import Foundation

nonisolated struct AuthUser: Codable, Sendable {
    let id: String
    let email: String?
    let createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

nonisolated struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
    let user: AuthUser

    nonisolated enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

nonisolated struct AuthErrorResponse: Codable, Sendable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?
    let errorCode: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
        case message
        case errorCode = "error_code"
    }

    var displayMessage: String {
        msg ?? message ?? errorDescription ?? error ?? "Erro desconhecido"
    }
}

nonisolated struct UserProfile: Codable, Sendable {
    let id: String
    var fullName: String?
    var companyName: String?
    var phone: String?
    var subscriptionStatus: String?
    var subscriptionExpiresAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case companyName = "company_name"
        case phone
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
}
