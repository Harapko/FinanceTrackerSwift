import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let expiresAt: String?
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let defaultCurrencyCode: String
}

struct UserResponse: Decodable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let defaultCurrencyCode: String

    var fullName: String { "\(firstName) \(lastName)" }
}
