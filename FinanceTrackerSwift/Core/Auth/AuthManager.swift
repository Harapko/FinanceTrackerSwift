import Foundation
import Observation

@Observable
final class AuthManager {
    static let shared = AuthManager()

    var currentUser: UserResponse?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private init() {
        // Restore session ONLY if a non-empty token and valid user exist
        let token = KeychainHelper.shared.read(key: "finance_tracker_token")
        let userData = KeychainHelper.shared.read(key: "finance_tracker_user")

        if let token = token, !token.isEmpty,
           let userData = userData,
           let data = userData.data(using: .utf8),
           let user = try? JSONDecoder().decode(UserResponse.self, from: data) {
            currentUser = user
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response: AuthResponse = try await APIClient.shared.post(
                "/api/auth/login",
                body: LoginRequest(email: email, password: password)
            )
            handleAuthSuccess(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Register
    func register(firstName: String, lastName: String, email: String, password: String, currencyCode: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response: AuthResponse = try await APIClient.shared.post(
                "/api/auth/register",
                body: RegisterRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password,
                    defaultCurrencyCode: currencyCode
                )
            )
            handleAuthSuccess(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Logout
    func logout() {
        KeychainHelper.shared.delete(key: "finance_tracker_token")
        KeychainHelper.shared.delete(key: "finance_tracker_user")
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Handle success (both login & register return AuthResponse)
    private func handleAuthSuccess(_ response: AuthResponse) {
        // Persist token
        KeychainHelper.shared.save(key: "finance_tracker_token", value: response.accessToken)

        // Persist user as JSON
        if let data = try? JSONEncoder().encode(response.user),
           let json = String(data: data, encoding: .utf8) {
            KeychainHelper.shared.save(key: "finance_tracker_user", value: json)
        }

        currentUser = response.user
        isAuthenticated = true
    }
}
