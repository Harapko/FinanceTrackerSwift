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
        // Check if token exists on startup
        if let _ = KeychainHelper.shared.read(key: "finance_tracker_token") {
            isAuthenticated = true
            Task { await fetchCurrentUser() }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response: LoginResponse = try await APIClient.shared.post(
                "/api/auth/login",
                body: LoginRequest(email: email, password: password)
            )
            KeychainHelper.shared.save(key: "finance_tracker_token", value: response.token)
            isAuthenticated = true
            await fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(firstName: String, lastName: String, email: String, password: String, currencyCode: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let _: UserResponse = try await APIClient.shared.post(
                "/api/auth/register",
                body: RegisterRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password,
                    defaultCurrencyCode: currencyCode
                )
            )
            await login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        KeychainHelper.shared.delete(key: "finance_tracker_token")
        currentUser = nil
        isAuthenticated = false
    }

    func fetchCurrentUser() async {
        do {
            let user: UserResponse = try await APIClient.shared.get("/api/auth/me")
            currentUser = user
        } catch {
            // Token invalid — log out
            logout()
        }
    }
}
