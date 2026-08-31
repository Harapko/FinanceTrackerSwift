import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var currency = "USD"

    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "AUD", "CHF"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0f0c29"), Color(hex: "302b63"), Color(hex: "24243e")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "a78bfa"), Color(hex: "818cf8")],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(L10n.Auth.createAccount)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            authField(L10n.Auth.firstName, text: $firstName, icon: "person")
                            authField(L10n.Auth.lastName, text: $lastName, icon: "person")
                        }
                        authField(L10n.Auth.email, text: $email, icon: "envelope")
                        authField(L10n.Auth.password, text: $password, icon: "lock", isSecure: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Auth.defaultCurrency, systemImage: "dollarsign.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.7))
                            Picker(L10n.Common.currency, selection: $currency) {
                                ForEach(currencies, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(14)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                        }

                        if let error = auth.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(12)
                            .background(Color(hex: "f87171").opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task {
                                await auth.register(firstName: firstName, lastName: lastName,
                                                    email: email, password: password, currencyCode: currency)
                            }
                        } label: {
                            Group {
                                if auth.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(L10n.Auth.createAccount).font(.headline).foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(auth.isLoading || firstName.isEmpty || email.isEmpty || password.isEmpty)

                        Button(LocalizedStringKey(L10n.Auth.alreadyHaveAccount)) { dismiss() }
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(28)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func authField(_ title: String, text: Binding<String>, icon: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.7))
            Group {
                if isSecure {
                    SecureField("••••••••", text: text)
                } else {
                    TextField(title, text: text)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
            }
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white)
        }
    }
}
