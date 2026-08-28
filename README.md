# FinanceTrackerSwift

A native SwiftUI Finance Tracker app for **iPhone (iOS 17+)** and **macOS (macOS 14+ Sonoma)**.

This app is the Swift counterpart of the [FinanceTracker](https://github.com/Harapko/FinanceTracker) React frontend — built entirely with SwiftUI and Swift Charts, connecting to the same .NET backend API.

---

## Screenshots

| Dashboard | Transactions | Analytics | Savings |
|---|---|---|---|
| Stats, charts, accounts | Filter & search | Cash Flow & Net Worth | Goals with progress |

---

## Features

- 🔐 **JWT Authentication** — Login / Register with secure Keychain token storage
- 📊 **Dashboard** — Net Worth, Income, Expenses, Savings Rate cards + Balance History line chart + Expense by Category donut
- 💸 **Transactions** — Full paginated list with search, type, date filters and swipe-to-delete
- 🏦 **Accounts** — All accounts with expandable sub-accounts, create/delete
- 📈 **Analytics**
  - **Cash Flow Tab**: Overview cards, monthly bar+line chart, expense/income category pies, top spending
  - **Net Worth Tab**: Net worth summary, asset allocation donut, investment holdings table, account breakdown
- 🎯 **Savings Goals** — Create, edit, contribute, delete goals with animated progress bars

---

## Platform Support

| Feature | iPhone | macOS |
|---|---|---|
| Navigation | `TabView` (5 tabs) | `NavigationSplitView` with sidebar |
| Modals | Full-screen sheets | Modal sheets |
| Charts | Swift Charts | Swift Charts |

---

## Tech Stack

| Library | Purpose |
|---|---|
| **SwiftUI** | UI framework |
| **Swift Charts** | Balance History, Cash Flow, Donut/Pie charts |
| **URLSession** | HTTP networking (async/await) |
| **Security.framework** | Keychain token storage |
| **Observation** (`@Observable`) | State management |

> ⚠️ No third-party dependencies — 100% native Apple frameworks.

---

## Setup

### Requirements
- Xcode 15.2+
- iOS 17+ Simulator or device
- macOS 14+ (Sonoma) for macOS target
- The [FinanceTracker .NET backend](https://github.com/Harapko/FinanceTracker) running

### Configure API URL

By default the app connects to `http://localhost:5237`. To change this:

1. Open the scheme in Xcode → **Edit Scheme → Run → Arguments → Environment Variables**
2. Add `API_BASE_URL` = `https://your-backend.com`

Or update `AppConfig.baseURL` in [`APIClient.swift`](FinanceTrackerSwift/Core/Network/APIClient.swift).

### Build

```bash
# Open in Xcode
open FinanceTrackerSwift.xcodeproj

# Or via xcodebuild (iPhone simulator)
xcodebuild -project FinanceTrackerSwift.xcodeproj \
           -scheme FinanceTrackerSwift \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

---

## Project Structure

```
FinanceTrackerSwift/
├── App/
│   ├── FinanceTrackerSwiftApp.swift    # @main entry
│   └── ContentView.swift               # Root auth gate + TabView / NavigationSplitView
├── Core/
│   ├── Network/APIClient.swift         # URLSession async/await client
│   ├── Auth/
│   │   ├── AuthManager.swift           # @Observable auth state
│   │   └── KeychainHelper.swift        # Secure token storage
│   └── Extensions/Color+Hex.swift      # Hex color + currency formatter
├── Models/
│   ├── AccountModels.swift
│   ├── TransactionModels.swift
│   ├── SavingsGoalModels.swift
│   ├── AnalyticsModels.swift
│   └── UserModels.swift
├── Services/
│   ├── AccountService.swift
│   ├── TransactionService.swift
│   ├── SavingsGoalService.swift
│   └── AnalyticsService.swift
└── Views/
    ├── Auth/          LoginView, RegisterView
    ├── Dashboard/     DashboardView, Charts, Recent Transactions
    ├── Transactions/  TransactionsView, Filters, AddTransaction
    ├── Accounts/      AccountsView, AccountCard, AddAccount
    ├── Analytics/     AnalyticsView (CashFlow + NetWorth tabs)
    └── Savings/       SavingsView, GoalCard, AddGoal, Contribute
```

---

## Related Repos

- **Backend API**: [Harapko/FinanceTracker](https://github.com/Harapko/FinanceTracker) — .NET 8 Web API
- **Web Frontend**: [Harapko/FinanceTracker](https://github.com/Harapko/FinanceTracker/tree/main/finance-tracker-web-interface) — React + TypeScript

---

## License

MIT © Maksym Harapko
