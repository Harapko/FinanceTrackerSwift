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
        // Initial quick load
        let token = KeychainHelper.shared.read(key: "finance_tracker_token")
        let userData = KeychainHelper.shared.read(key: "finance_tracker_user")

        if let token = token, !token.isEmpty,
           let userData = userData,
           let data = userData.data(using: .utf8),
           let user = try? JSONDecoder().decode(UserResponse.self, from: data) {
            currentUser = user
            isAuthenticated = true
            // Validate asynchronously with the active backend
            Task { await validateSession() }
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Validate Session against active server
    func validateSession() async {
        guard let token = KeychainHelper.shared.read(key: "finance_tracker_token"), !token.isEmpty else {
            logout()
            return
        }

        do {
            let user: UserResponse = try await APIClient.shared.get("/api/auth/me")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            // Token is invalid on this server (e.g. from local DB when connecting to Render cloud)
            await MainActor.run {
                self.logout()
            }
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

    // MARK: - Update Profile
    @discardableResult
    func updateProfile(firstName: String, lastName: String, defaultCurrencyCode: String) async throws -> UserResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updatedUser: UserResponse = try await APIClient.shared.put(
                "/api/auth/me",
                body: UpdateUserRequest(
                    firstName: firstName,
                    lastName: lastName,
                    defaultCurrencyCode: defaultCurrencyCode,
                    timezone: currentUser?.timezone ?? "UTC"
                )
            )
            await MainActor.run {
                self.currentUser = updatedUser
                // Persist updated user as JSON
                if let data = try? JSONEncoder().encode(updatedUser),
                   let json = String(data: data, encoding: .utf8) {
                    KeychainHelper.shared.save(key: "finance_tracker_user", value: json)
                }
            }
            return updatedUser
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
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
