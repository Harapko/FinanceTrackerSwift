import SwiftUI

enum AppTab: Int, Hashable, CaseIterable {
    case dashboard = 0
    case transactions = 1
    case accounts = 2
    case analytics = 3
    case savings = 4
}

// Environment key to allow child views to switch tabs
private struct AppTabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<AppTab> = .constant(.dashboard)
}

extension EnvironmentValues {
    var selectedTab: Binding<AppTab> {
        get { self[AppTabSelectionKey.self] }
        set { self[AppTabSelectionKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
                    .environment(\.selectedTab, $selectedTab)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

// MARK: - Main Navigation
struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: iOS Tab View
    var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                TransactionsView()
            }
            .tabItem {
                Label("Transactions", systemImage: "arrow.left.arrow.right")
            }
            .tag(AppTab.transactions)

            NavigationStack {
                AccountsView()
            }
            .tabItem {
                Label("Accounts", systemImage: "building.columns")
            }
            .tag(AppTab.accounts)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.pie")
            }
            .tag(AppTab.analytics)

            NavigationStack {
                SavingsView()
            }
            .tabItem {
                Label("Savings", systemImage: "target")
            }
            .tag(AppTab.savings)
        }
        .tint(Color(hex: "a78bfa"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "161b22"))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // MARK: macOS Sidebar Layout
    var macOSLayout: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            NavigationStack {
                switch selectedTab {
                case .dashboard: DashboardView()
                case .transactions: TransactionsView()
                case .accounts: AccountsView()
                case .analytics: AnalyticsView()
                case .savings: SavingsView()
                }
            }
        }
    }
}

// MARK: - macOS Sidebar
struct SidebarView: View {
    @Environment(AuthManager.self) private var auth
    @Binding var selectedTab: AppTab

    enum SidebarItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case transactions = "Transactions"
        case accounts = "Accounts"
        case analytics = "Analytics"
        case savings = "Savings"

        var tab: AppTab {
            switch self {
            case .dashboard: return .dashboard
            case .transactions: return .transactions
            case .accounts: return .accounts
            case .analytics: return .analytics
            case .savings: return .savings
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .transactions: return "arrow.left.arrow.right"
            case .accounts: return "building.columns"
            case .analytics: return "chart.pie"
            case .savings: return "target"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return Color(hex: "818cf8")
            case .transactions: return Color(hex: "60a5fa")
            case .accounts: return Color(hex: "34d399")
            case .analytics: return Color(hex: "fbbf24")
            case .savings: return Color(hex: "a78bfa")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Finance").font(.headline.bold())
                    Text("Tracker").font(.caption).opacity(0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Divider().opacity(0.2)

            List(SidebarItem.allCases, id: \.self) { item in
                Button {
                    selectedTab = item.tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .foregroundColor(item.color)
                        Text(item.rawValue)
                            .foregroundColor(.primary)
                    }
                }
                .listRowBackground(selectedTab == item.tab ? item.color.opacity(0.15) : Color.clear)
            }
            .listStyle(.sidebar)

            Spacer()

            Divider().opacity(0.2)

            // User + logout
            HStack {
                if let user = auth.currentUser {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullName).font(.caption.bold())
                        Text(user.email).font(.caption2).opacity(0.5)
                    }
                }
                Spacer()
                Button {
                    auth.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }
}
