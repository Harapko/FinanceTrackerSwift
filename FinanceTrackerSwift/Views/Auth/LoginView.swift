import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0f0c29"), Color(hex: "302b63"), Color(hex: "24243e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo / Title
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(hex: "a78bfa"), Color(hex: "818cf8")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("Finance Tracker")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("Track your financial future")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.bottom, 8)

                // Form card
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Email", systemImage: "envelope")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                        TextField("you@example.com", text: $email)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Password", systemImage: "lock")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                        SecureField("••••••••", text: $password)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                    }

                    if let error = auth.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(Color(hex: "f87171"))
                        .padding(12)
                        .background(Color(hex: "f87171").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        Task { await auth.login(email: email, password: password) }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showRegister = true
                    } label: {
                        Text("Don't have an account? **Register**")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                .padding(28)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environment(auth)
        }
    }
}
