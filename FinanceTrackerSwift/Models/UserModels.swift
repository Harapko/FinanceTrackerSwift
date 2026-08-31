import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let defaultCurrencyCode: String
}

struct UpdateUserRequest: Encodable {
    let firstName: String?
    let lastName: String?
    let defaultCurrencyCode: String?
    let timezone: String?
}

struct UserResponse: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let defaultCurrencyCode: String
    let timezone: String?
    let createdAtUtc: String?

    var fullName: String { "\(firstName) \(lastName)" }
}

/// The actual shape returned by /api/auth/login and /api/auth/register
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: String
    let user: UserResponse
}
