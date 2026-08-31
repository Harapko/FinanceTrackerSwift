import SwiftUI

struct UserProfileSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    @State private var serverURL: String = AppConfig.baseURL
    @State private var isCustomServer = false

    var userInitial: String {
        auth.currentUser?.firstName.prefix(1).uppercased() ?? "U"
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

                VStack(spacing: 24) {
                    // Avatar & User Info
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "818cf8").opacity(0.3), radius: 10, x: 0, y: 5)

                            Text(userInitial)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 4) {
                            Text(auth.currentUser?.fullName ?? "User Profile")
                                .font(.title3.bold())
                                .foregroundColor(.white)

                            Text(auth.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 20)

                    // Account & Server Details Card
                    VStack(spacing: 12) {
                        profileRow(title: "Default Currency", value: auth.currentUser?.defaultCurrencyCode ?? "USD", icon: "dollarsign.circle")
                        Divider().background(Color.white.opacity(0.06))
                        profileRow(title: "API Endpoint", value: serverDisplayValue, icon: "network", valueColor: Color(hex: "818cf8"))
                        Divider().background(Color.white.opacity(0.06))
                        profileRow(title: "Status", value: "Active", icon: "checkmark.seal.fill", valueColor: Color(hex: "34d399"))
                        Divider().background(Color.white.opacity(0.06))
                        profileRow(title: "Platform", value: "Finance Tracker iOS", icon: "iphone")
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))

                    // Quick Server Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API SERVER TARGET")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))

                        HStack(spacing: 8) {
                            Button {
                                AppConfig.setBaseURL(AppConfig.localBaseURL)
                                serverURL = AppConfig.localBaseURL
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "laptopcomputer")
                                    Text("Localhost (.NET)")
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

                    Spacer()

                    // Log Out Button
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
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
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

    private func profileRow(title: String, value: String, icon: String, valueColor: Color = .white) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(valueColor)
        }
    }
}
