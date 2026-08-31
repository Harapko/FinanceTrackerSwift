import SwiftUI

struct UserProfileSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var defaultCurrencyCode: String = "USD"
    @State private var serverURL: String = AppConfig.baseURL
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showLogoutConfirmation = false

    let currencies: [(code: String, symbol: String, name: String)] = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("UAH", "₴", "Ukrainian Hryvnia"),
        ("PLN", "zł", "Polish Zloty"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "C$", "Canadian Dollar"),
        ("CHF", "Fr", "Swiss Franc")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Avatar Card
                        avatarSection

                        // Personal Info Section
                        personalInfoSection

                        // Currency Section
                        currencySection

                        // Language Section
                        languageSection

                        // Server URL Section
                        serverSection

                        // Save Button
                        saveButtonSection

                        // Logout Button
                        logoutSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.Profile.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .onAppear {
                if let user = auth.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    defaultCurrencyCode = user.defaultCurrencyCode
                }
                serverURL = AppConfig.baseURL
            }
            .alert(L10n.Profile.profileUpdated, isPresented: $showSuccessAlert) {
                Button(L10n.Common.done, role: .cancel) {
                    dismiss()
                }
            }
            .confirmationDialog(
                L10n.Profile.logOutConfirmTitle,
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.Profile.logOut, role: .destructive) {
                    auth.logout()
                    dismiss()
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Profile.logOutConfirmMsg)
            }
        }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text(auth.currentUser?.firstName.prefix(1).uppercased() ?? "U")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(auth.currentUser?.fullName ?? "")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Text(auth.currentUser?.email ?? "")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.Profile.personalInfo, systemImage: "person.fill")
                .font(.subheadline.bold())
                .foregroundColor(Color.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Profile.firstName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))

                TextField(L10n.Profile.firstName, text: $firstName)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Profile.lastName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))

                TextField(L10n.Profile.lastName, text: $lastName)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Profile.email)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))

                Text(auth.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Currency Section
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.Profile.primaryCurrency, systemImage: "dollarsign.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(Color.white.opacity(0.7))

            Text(L10n.Profile.primaryCurrencyDesc)
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.4))

            Menu {
                ForEach(currencies, id: \.code) { curr in
                    Button {
                        defaultCurrencyCode = curr.code
                    } label: {
                        HStack {
                            Text("\(curr.symbol) \(curr.code) — \(curr.name)")
                            if defaultCurrencyCode == curr.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selected = currencies.first(where: { $0.code == defaultCurrencyCode }) {
                        Text(selected.symbol)
                            .font(.headline.bold())
                            .foregroundColor(Color(hex: "a78bfa"))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(selected.code) — \(selected.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(defaultCurrencyCode)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.Profile.interfaceLanguage, systemImage: "globe")
                .font(.subheadline.bold())
                .foregroundColor(Color.white.opacity(0.7))

            VStack(spacing: 8) {
                // English option
                Button {
                    localization.setLanguage(.english)
                } label: {
                    HStack(spacing: 10) {
                        Text("🇺🇸")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("English")
                                .font(.subheadline.bold())
                                .foregroundColor(!localization.isUkrainian ? .white : Color.white.opacity(0.7))
                            Text("English (US)")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        Spacer()
                        if !localization.isUkrainian {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
                    .padding(12)
                    .background(!localization.isUkrainian ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!localization.isUkrainian ? Color(hex: "a78bfa") : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Ukrainian option
                Button {
                    localization.setLanguage(.ukrainian)
                } label: {
                    HStack(spacing: 10) {
                        Text("🇺🇦")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Українська")
                                .font(.subheadline.bold())
                                .foregroundColor(localization.isUkrainian ? .white : Color.white.opacity(0.7))
                            Text("Ukrainian")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        Spacer()
                        if localization.isUkrainian {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
                    .padding(12)
                    .background(localization.isUkrainian ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(localization.isUkrainian ? Color(hex: "a78bfa") : Color.white.opacity(0.08), lineWidth: 1)
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
            Label(L10n.Profile.apiServerTarget, systemImage: "network")
                .font(.subheadline.bold())
                .foregroundColor(Color.white.opacity(0.7))

            HStack(spacing: 8) {
                Button {
                    AppConfig.setBaseURL(AppConfig.localBaseURL)
                    serverURL = AppConfig.localBaseURL
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "laptopcomputer")
                        Text(L10n.Profile.localhost)
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
                        Text(L10n.Profile.cloudApi)
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
                    Text(isSaving ? L10n.Profile.savingChanges : L10n.Profile.saveChanges)
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
                Text(L10n.Profile.logOut)
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
