import SwiftUI

struct UserProfileSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var defaultCurrencyCode: String = "USD"
    @State private var selectedLanguage: String = "en"
    @State private var serverURL: String = AppConfig.baseURL

    @State private var isSaving: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String?
    @State private var showLogoutConfirmation: Bool = false

    private let availableCurrencies: [(code: String, symbol: String, flag: String, name: String)] = [
        ("USD", "$", "🇺🇸", "US Dollar"),
        ("EUR", "€", "🇪🇺", "Euro"),
        ("GBP", "£", "🇬🇧", "British Pound"),
        ("UAH", "₴", "🇺🇦", "Ukrainian Hryvnia"),
        ("PLN", "zł", "🇵🇱", "Polish Zloty"),
        ("JPY", "¥", "🇯🇵", "Japanese Yen"),
        ("CAD", "C$", "🇨🇦", "Canadian Dollar"),
        ("CHF", "CHF", "🇨🇭", "Swiss Franc"),
        ("AUD", "A$", "🇦🇺", "Australian Dollar"),
    ]

    var userInitial: String {
        let name = firstName.isEmpty ? (auth.currentUser?.firstName ?? "U") : firstName
        return name.prefix(1).uppercased()
    }

    var hasChanges: Bool {
        guard let user = auth.currentUser else { return false }
        return firstName != user.firstName ||
               lastName != user.lastName ||
               defaultCurrencyCode != user.defaultCurrencyCode
    }

    var serverDisplayValue: String {
        if AppConfig.baseURL.contains("localhost") || AppConfig.baseURL.contains("127.0.0.1") {
            return "Localhost (.NET :5237)"
        } else if AppConfig.baseURL.contains("onrender.com") {
            return "Render Cloud"
        }
        return AppConfig.baseURL
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Avatar & User Header
                        headerSection

                        // 2. Personal Information Card
                        personalInfoSection

                        // 3. Primary Base Currency Card
                        currencySection

                        // 4. Interface Language Card
                        languageSection

                        // 5. API Server Selector Card
                        serverSection

                        // 6. Save Changes Button
                        saveButtonSection

                        // 7. Log Out Section
                        logoutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .onAppear {
                if let user = auth.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    defaultCurrencyCode = user.defaultCurrencyCode
                }
                selectedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "en"
            }
            .alert("Profile Updated", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile details and primary base currency have been saved successfully.")
            }
            .confirmationDialog(
                "Log Out",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    dismiss()
                    auth.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out of your account?")
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 76, height: 76)
                    .shadow(color: Color(hex: "818cf8").opacity(0.35), radius: 12, x: 0, y: 6)

                Text(userInitial)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("\(firstName) \(lastName)")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(auth.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Personal Information
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Personal Information", systemImage: "person.fill")
                .font(.headline)
                .foregroundColor(Color(hex: "818cf8"))

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("First Name")
                        .font(.caption.bold())
                        .foregroundColor(Color.white.opacity(0.7))

                    TextField("First Name", text: $firstName)
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Last Name")
                        .font(.caption.bold())
                        .foregroundColor(Color.white.opacity(0.7))

                    TextField("Last Name", text: $lastName)
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email (Account)")
                        .font(.caption.bold())
                        .foregroundColor(Color.white.opacity(0.5))

                    HStack {
                        Text(auth.currentUser?.email ?? "user@example.com")
                            .foregroundColor(Color.white.opacity(0.5))
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Primary Currency
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Primary Base Currency", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                    .foregroundColor(Color(hex: "34d399"))
                Spacer()
                Text(defaultCurrencyCode)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "34d399").opacity(0.15))
                    .foregroundColor(Color(hex: "34d399"))
                    .clipShape(Capsule())
            }

            Text("Aggregates net worth, dashboards, and portfolio metrics across all accounts.")
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.6))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(availableCurrencies, id: \.code) { item in
                    let isSelected = defaultCurrencyCode == item.code
                    Button {
                        defaultCurrencyCode = item.code
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.flag)
                                .font(.title3)
                            Text(item.code)
                                .font(.subheadline.bold())
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                            Text(item.symbol)
                                .font(.caption2)
                                .foregroundColor(isSelected ? Color(hex: "a78bfa") : Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ?
                            LinearGradient(colors: [Color(hex: "818cf8").opacity(0.3), Color(hex: "a78bfa").opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color(hex: "818cf8") : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Language
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Interface Language", systemImage: "globe")
                .font(.headline)
                .foregroundColor(Color(hex: "a78bfa"))

            HStack(spacing: 12) {
                // English option
                Button {
                    selectedLanguage = "en"
                    UserDefaults.standard.set("en", forKey: "app_language")
                } label: {
                    HStack(spacing: 10) {
                        Text("🇬🇧")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("English")
                                .font(.subheadline.bold())
                                .foregroundColor(selectedLanguage == "en" ? .white : Color.white.opacity(0.7))
                            Text("Default")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        Spacer()
                        if selectedLanguage == "en" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
                    .padding(12)
                    .background(selectedLanguage == "en" ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedLanguage == "en" ? Color(hex: "a78bfa") : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Ukrainian option
                Button {
                    selectedLanguage = "uk"
                    UserDefaults.standard.set("uk", forKey: "app_language")
                } label: {
                    HStack(spacing: 10) {
                        Text("🇺🇦")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Українська")
                                .font(.subheadline.bold())
                                .foregroundColor(selectedLanguage == "uk" ? .white : Color.white.opacity(0.7))
                            Text("Ukrainian")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        Spacer()
                        if selectedLanguage == "uk" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
                    .padding(12)
                    .background(selectedLanguage == "uk" ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedLanguage == "uk" ? Color(hex: "a78bfa") : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Server Selector
    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("API Server Target", systemImage: "network")
                .font(.subheadline.bold())
                .foregroundColor(Color.white.opacity(0.7))

            HStack(spacing: 8) {
                Button {
                    AppConfig.setBaseURL(AppConfig.localBaseURL)
                    serverURL = AppConfig.localBaseURL
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "laptopcomputer")
                        Text("Localhost (:5237)")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppConfig.baseURL == AppConfig.localBaseURL ? .white : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        AppConfig.baseURL == AppConfig.localBaseURL ?
                        Color(hex: "818cf8") : Color.white.opacity(0.05)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    AppConfig.setBaseURL(AppConfig.remoteBaseURL)
                    serverURL = AppConfig.remoteBaseURL
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.fill")
                        Text("Cloud API")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppConfig.baseURL == AppConfig.remoteBaseURL ? .white : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        AppConfig.baseURL == AppConfig.remoteBaseURL ?
                        Color(hex: "818cf8") : Color.white.opacity(0.05)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Save Button
    private var saveButtonSection: some View {
        VStack(spacing: 10) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Color(hex: "f87171"))
                    .multilineTextAlignment(.center)
            }

            Button {
                saveProfile()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(isSaving ? "Saving Changes..." : "Save Changes")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "818cf8").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isSaving || firstName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(firstName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
        }
    }

    // MARK: - Logout
    private var logoutSection: some View {
        Button(role: .destructive) {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                Text("Log Out")
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(hex: "ef4444"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "ef4444").opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // MARK: - Save Action
    private func saveProfile() {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                _ = try await auth.updateProfile(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    defaultCurrencyCode: defaultCurrencyCode
                )
                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
