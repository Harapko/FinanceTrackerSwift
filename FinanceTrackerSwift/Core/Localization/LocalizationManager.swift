import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case ukrainian = "uk"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .english: return "English"
        case .ukrainian: return "Українська"
        }
    }

    public var shortCode: String {
        switch self {
        case .english: return "EN"
        case .ukrainian: return "UA"
        }
    }

    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .ukrainian: return "🇺🇦"
        }
    }
}

@Observable
public final class LocalizationManager {
    public static let shared = LocalizationManager()

    public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }

    private init() {
        let savedLang = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .english
    }

    public func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    public var isUkrainian: Bool {
        currentLanguage == .ukrainian
    }

    public var currentLocale: Locale {
        isUkrainian ? Locale(identifier: "uk_UA") : Locale(identifier: "en_US")
    }
}

// MARK: - Typed L10n Localization Namespace
public enum L10n {
    private static var isUk: Bool {
        LocalizationManager.shared.isUkrainian
    }

    // MARK: - Common
    public enum Common {
        public static var save: String { isUk ? "Зберегти" : "Save" }
        public static var saving: String { isUk ? "Збереження..." : "Saving..." }
        public static var cancel: String { isUk ? "Скасувати" : "Cancel" }
        public static var delete: String { isUk ? "Видалити" : "Delete" }
        public static var edit: String { isUk ? "Редагувати" : "Edit" }
        public static var create: String { isUk ? "Створити" : "Create" }
        public static var processing: String { isUk ? "Обробка..." : "Processing..." }
        public static var refresh: String { isUk ? "Оновити" : "Refresh" }
        public static var close: String { isUk ? "Закрити" : "Close" }
        public static var loading: String { isUk ? "Завантаження..." : "Loading..." }
        public static var display: String { isUk ? "Показ" : "Display" }
        public static var currency: String { isUk ? "Валюта" : "Currency" }
        public static var date: String { isUk ? "Дата" : "Date" }
        public static var time: String { isUk ? "Час" : "Time" }
        public static var actions: String { isUk ? "Дії" : "Actions" }
        public static var search: String { isUk ? "Пошук" : "Search" }
        public static var clear: String { isUk ? "Очистити" : "Clear" }
        public static var clearFilters: String { isUk ? "Скинути фільтри" : "Clear Filters" }
        public static var all: String { isUk ? "Всі" : "All" }
        public static var status: String { isUk ? "Статус" : "Status" }
        public static var name: String { isUk ? "Назва" : "Name" }
        public static var description: String { isUk ? "Опис" : "Description" }
        public static var optional: String { isUk ? "Необов'язково" : "Optional" }
        public static var confirmDelete: String { isUk ? "Ви впевнені, що хочете це видалити?" : "Are you sure you want to delete this?" }
        public static var yes: String { isUk ? "Так" : "Yes" }
        public static var no: String { isUk ? "Ні" : "No" }
        public static var undo: String { isUk ? "Скасувати" : "Undo" }
        public static var to: String { isUk ? "до" : "to" }
        public static var error: String { isUk ? "Сталася помилка" : "An error occurred" }
        public static var filter: String { isUk ? "Фільтр" : "Filter" }
        public static var done: String { isUk ? "Готово" : "Done" }
        public static var apply: String { isUk ? "Застосувати" : "Apply" }
        public static var reset: String { isUk ? "Скинути" : "Reset" }
    }

    // MARK: - Navigation
    public enum Nav {
        public static var dashboard: String { isUk ? "Дашборд" : "Dashboard" }
        public static var accounts: String { isUk ? "Рахунки" : "Accounts" }
        public static var transactions: String { isUk ? "Транзакції" : "Transactions" }
        public static var savings: String { isUk ? "Цілі заощаджень" : "Savings Goals" }
        public static var analytics: String { isUk ? "Аналітика" : "Analytics" }
        public static var profile: String { isUk ? "Профіль та налаштування" : "Profile & Settings" }
        public static var logout: String { isUk ? "Вийти" : "Logout" }
        public static var appTitle: String { "Finance" }
        public static var appSubtitle: String { isUk ? "Трекер" : "Tracker" }
    }

    // MARK: - Auth
    public enum Auth {
        public static var tagline: String { isUk ? "Контролюйте ваші персональні фінанси" : "Track your financial future" }
        public static var signIn: String { isUk ? "Увійти" : "Sign In" }
        public static var signUp: String { isUk ? "Зареєструватися" : "Sign Up" }
        public static var createAccount: String { isUk ? "Створити акаунт" : "Create Account" }
        public static var firstName: String { isUk ? "Ім'я" : "First Name" }
        public static var lastName: String { isUk ? "Прізвище" : "Last Name" }
        public static var email: String { isUk ? "Електронна пошта" : "Email" }
        public static var emailAddress: String { isUk ? "Електронна пошта" : "Email Address" }
        public static var password: String { isUk ? "Пароль" : "Password" }
        public static var primaryCurrency: String { isUk ? "Основна валюта" : "Primary Currency" }
        public static var defaultCurrency: String { isUk ? "Основна валюта" : "Default Currency" }
        public static var welcomeBack: String { isUk ? "З поверненням!" : "Welcome back!" }
        public static var dontHaveAccount: String { isUk ? "Немає акаунта? **Зареєструватися**" : "Don't have an account? **Register**" }
        public static var alreadyHaveAccount: String { isUk ? "Вже маєте акаунт? **Увійти**" : "Already have an account? **Sign In**" }
    }

    // MARK: - Dashboard
    public enum Dashboard {
        public static var title: String { isUk ? "Огляд" : "Overview" }
        public static var subtitle: String { isUk ? "З поверненням. Ось ваш фінансовий підсумок." : "Welcome back. Here is your financial summary." }
        public static var refreshDashboard: String { isUk ? "Оновити дашборд" : "Refresh Dashboard" }
        public static var addTransaction: String { isUk ? "Додати транзакцію" : "Add Transaction" }
        public static var netWorth: String { isUk ? "Чиста вартість" : "Net Worth" }
        public static var assets: String { isUk ? "Активи" : "Assets" }
        public static var monthlyIncome: String { isUk ? "Дохід за місяць" : "Monthly Income" }
        public static var earningsSubtitle: String { isUk ? "Заробіток за цей місяць" : "Earnings this month" }
        public static var monthlyExpenses: String { isUk ? "Витрати за місяць" : "Monthly Expenses" }
        public static var spendingSubtitle: String { isUk ? "Витрати за цей місяць" : "Spending this month" }
        public static var savingsRate: String { isUk ? "Норма заощаджень" : "Savings Rate" }
        public static var netSavings: String { isUk ? "Чисті заощадження" : "Net Savings" }
        public static var balanceHistory: String { isUk ? "Історія балансу" : "Balance History" }
        public static var noBalanceHistory: String { isUk ? "Історія балансу поки відсутня" : "No balance history" }
        public static var totalBalance: String { isUk ? "Загальний баланс" : "Total Balance" }
        public static var current: String { isUk ? "Поточний" : "Current" }
        public static var expensesByCategory: String { isUk ? "Витрати за категоріями" : "Expenses by Category" }
        public static var noExpenses: String { isUk ? "Немає витрат за цей період" : "No expenses this period" }
        public static var recentTransactions: String { isUk ? "Останні транзакції" : "Recent Transactions" }
        public static var viewAll: String { isUk ? "Усі транзакції" : "View All" }
        public static var seeAll: String { isUk ? "Всі" : "See All" }
        public static var noRecentTransactions: String { isUk ? "Останніх транзакцій не знайдено" : "No recent transactions" }
        public static var yourAccounts: String { isUk ? "Ваші рахунки" : "Your Accounts" }
        public static var noAccountsYet: String { isUk ? "Рахунків ще немає" : "No accounts added yet" }
        public static var income: String { isUk ? "Дохід" : "Income" }
        public static var expense: String { isUk ? "Витрати" : "Expenses" }
        public static var total: String { isUk ? "Всього" : "Total" }
        public static var trader: String { isUk ? "Користувач" : "Trader" }

        public static func greeting(timeOfDay: String, name: String) -> String {
            if isUk {
                let greetingWord: String
                switch timeOfDay.lowercased() {
                case "morning": greetingWord = "Доброго ранку"
                case "afternoon": greetingWord = "Доброго дня"
                case "evening": greetingWord = "Доброго вечора"
                default: greetingWord = "Привіт"
                }
                return "\(greetingWord), \(name)"
            } else {
                return "Good \(timeOfDay), \(name)"
            }
        }

        public static func assetsFormatted(_ formatted: String) -> String {
            if isUk {
                return "Активи: \(formatted)"
            } else {
                return "Assets: \(formatted)"
            }
        }

        public static func netFormatted(_ formatted: String) -> String {
            if isUk {
                return "Чисті: \(formatted)"
            } else {
                return "Net: \(formatted)"
            }
        }
    }

    // MARK: - Accounts
    public enum Accounts {
        public static var title: String { isUk ? "Рахунки та портфелі" : "Accounts & Portfolios" }
        public static var pageTitle: String { isUk ? "Рахунки" : "Accounts" }
        public static func accountsSummary(count: Int, netWorth: String) -> String {
            if isUk {
                let word: String
                if count % 10 == 1 && count % 100 != 11 {
                    word = "рахунок"
                } else if [2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100) {
                    word = "рахунки"
                } else {
                    word = "рахунків"
                }
                return "\(count) \(word) • Вартість активів: \(netWorth)"
            } else {
                let word = count == 1 ? "account" : "accounts"
                return "\(count) \(word) • Net Worth: \(netWorth)"
            }
        }
        public static var subtitle: String { isUk ? "Керуйте банківськими рахунками, криптогаманцями та активами." : "Manage your bank accounts, crypto wallets, and investment portfolios." }
        public static var newAccount: String { isUk ? "Новий рахунок" : "New Account" }
        public static var addAccount: String { isUk ? "Рахунок" : "Account" }
        public static var addAsset: String { isUk ? "Актив" : "Asset" }
        public static var buyAddAsset: String { isUk ? "Купити / Додати актив (Акції/Крипта)" : "Buy / Add Asset (Stock/Crypto)" }
        public static var emptyTitle: String { isUk ? "Рахунків ще немає" : "No accounts yet" }
        public static var emptySubtitle: String { isUk ? "Почніть зі створення розрахункового, ощадного, інвестиційного чи крипторахунку." : "Get started by creating your primary checking, savings, investment, or crypto account." }
        public static var createFirstAccount: String { isUk ? "Додати перший рахунок" : "Add Your First Account" }
        public static var totalBalance: String { isUk ? "Загальний баланс" : "Total Balance" }
        public static var subAccounts: String { isUk ? "Субрахунки" : "Sub-Accounts" }
        public static var addSubAccount: String { isUk ? "Додати субрахунок" : "Add Sub-Account" }
        public static var editAccount: String { isUk ? "Редагувати рахунок" : "Edit Account" }
        public static var deleteAccount: String { isUk ? "Видалити рахунок" : "Delete Account" }
        public static var editSubAccount: String { isUk ? "Редагувати субрахунок" : "Edit Sub-Account" }
        public static var deleteSubAccount: String { isUk ? "Видалити субрахунок" : "Delete Sub-Account" }
        public static var modalCreateTitle: String { isUk ? "Новий рахунок" : "New Account" }
        public static var modalEditTitle: String { isUk ? "Редагувати рахунок" : "Edit Account" }
        public static var modalCreateSubTitle: String { isUk ? "Новий субрахунок" : "New Sub-Account" }
        public static var modalEditSubTitle: String { isUk ? "Редагувати субрахунок" : "Edit Sub-Account" }
        public static var accountName: String { isUk ? "Назва рахунку" : "Account Name" }
        public static var accountNamePlaceholder: String { isUk ? "ПриватБанк, Монобанк, Crypto..." : "e.g. Chase Checking, Main Savings..." }
        public static var subAccountName: String { isUk ? "Назва субрахунку" : "Sub-Account Name" }
        public static var subAccountNamePlaceholder: String { isUk ? "Резервний фонд, Заощадження..." : "e.g. Emergency Savings" }
        public static var accountType: String { isUk ? "Тип рахунку" : "Account Type" }
        public static var initialBalance: String { isUk ? "Початковий баланс" : "Initial Balance" }
        public static var currentBalance: String { isUk ? "Поточний залишок" : "Current Cash Balance" }
        public static var balanceAdjustmentHint: String { isUk ? "Зміна цього значення автоматично створить коригувальну транзакцію." : "Changing this value will automatically create a balance adjustment transaction." }
        public static var parentAccountBalanceManagedBySubs: String { isUk ? "Баланс автоматично обчислюється із субрахунків. Редагуйте баланс кожного субрахунку окремо." : "Balance is calculated automatically from sub-accounts. Edit individual sub-account balances to adjust." }
        public static var subAccountType: String { isUk ? "Тип субрахунку" : "Sub-Account Type" }
        public static var typeBankAccount: String { isUk ? "Банківський рахунок" : "Bank Account" }
        public static var typeCreditCard: String { isUk ? "Кредитна картка" : "Credit Card" }
        public static var typeCryptoWallet: String { isUk ? "Криптогаманець" : "Crypto Wallet" }
        public static var typeInvestmentAccount: String { isUk ? "Інвестиційний рахунок" : "Investment Account" }
        public static var typeCash: String { isUk ? "Готівка" : "Cash" }
        public static var typeOther: String { isUk ? "Інше" : "Other" }
        public static var subTypeChecking: String { isUk ? "Розрахунковий" : "Checking" }
        public static var subTypeSavings: String { isUk ? "Ощадний" : "Savings" }
        public static var subTypeCredit: String { isUk ? "Кредитний" : "Credit" }
        public static var subTypeInvestment: String { isUk ? "Інвестиційний" : "Investment" }
        public static var subTypeCash: String { isUk ? "Готівковий" : "Cash" }
        public static var themeColor: String { isUk ? "Колір теми" : "Accent Color" }
        public static var descriptionOptional: String { isUk ? "Опис (необов'язково)" : "Description (optional)" }
        public static var descriptionPlaceholder: String { isUk ? "Примітки або опис..." : "Notes or description..." }
        public static var deleteConfirmTitle: String { isUk ? "Видалити рахунок" : "Delete Account" }
        public static func deleteConfirmMsg(name: String) -> String {
            isUk ? "Ви впевнені, що хочете видалити рахунок '\(name)'? Це також видалить усі його субрахунки та транзакції." : "Are you sure you want to delete '\(name)'? This will also remove all its sub-accounts and transactions."
        }
        public static var deleteSubConfirmTitle: String { isUk ? "Видалити субрахунок" : "Delete Sub-Account" }
        public static func deleteSubConfirmMsg(name: String) -> String {
            isUk ? "Ви впевнені, що хочете видалити '\(name)'?" : "Are you sure you want to delete '\(name)'?"
        }
        public static var holdingsAndAssets: String { isUk ? "Активи та інвестиції" : "Holdings & Assets" }
        public static func holdingsFormatted(_ formatted: String) -> String {
            isUk ? "Активи: \(formatted)" : "Holdings: \(formatted)"
        }
    }

    // MARK: - Categories
    public enum Categories {
        public static var title: String { isUk ? "Категорії" : "Categories" }
        public static var newCategory: String { isUk ? "Нова категорія" : "New Category" }
        public static var modalCreateTitle: String { isUk ? "Нова категорія" : "New Category" }
        public static var modalEditTitle: String { isUk ? "Редагувати категорію" : "Edit Category" }
        public static var createCategory: String { isUk ? "Створити категорію" : "Create Category" }
        public static var categoryName: String { isUk ? "Назва категорії" : "Category Name" }
        public static var namePlaceholder: String { isUk ? "напр., Продукти, Підписки..." : "e.g. Groceries, Gym, Freelance..." }
        public static var categoryType: String { isUk ? "Тип категорії" : "Category Type" }
        public static var typeExpense: String { isUk ? "Витрата" : "Expense" }
        public static var typeIncome: String { isUk ? "Дохід" : "Income" }
        public static var typeBoth: String { isUk ? "Обидва" : "Both" }
        public static var selectColor: String { isUk ? "Колір" : "Color" }
        public static var selectIcon: String { isUk ? "Іконка" : "Icon" }
        public static var customColor: String { isUk ? "Власний колір" : "Custom Color" }
        public static var hexCode: String { isUk ? "HEX код" : "Hex Code" }
        public static var searchIcons: String { isUk ? "Пошук іконки..." : "Search icons..." }
        public static var filterAll: String { isUk ? "Всі" : "All" }
        public static var filterFood: String { isUk ? "Їжа" : "Food" }
        public static var filterShopping: String { isUk ? "Шопінг" : "Shopping" }
        public static var filterTransport: String { isUk ? "Транспорт" : "Transport" }
        public static var filterHousing: String { isUk ? "Житло" : "Housing" }
        public static var filterHealth: String { isUk ? "Здоров'я" : "Health" }
        public static var filterEntertainment: String { isUk ? "Розваги" : "Entertainment" }
        public static var filterWork: String { isUk ? "Робота" : "Work" }
        public static var filterFinance: String { isUk ? "Фінанси" : "Finance" }
        public static var filterLife: String { isUk ? "Життя" : "Life" }
        public static var filterTools: String { isUk ? "Інструменти" : "Tools" }
    }

    // MARK: - Transactions
    public enum Transactions {
        public static var title: String { isUk ? "Транзакції" : "Transactions" }
        public static var subtitle: String { isUk ? "Відстежуйте, шукайте та керуйте доходами, витратами та переказами." : "Track, search, and manage all your income, expense, and transfer records." }
        public static var newTransaction: String { isUk ? "Нова транзакція" : "New Transaction" }
        public static var transferFunds: String { isUk ? "Переказ коштів" : "Transfer Funds" }
        public static var newCategory: String { isUk ? "Нова категорія" : "New Category" }
        public static var modalCreateTitle: String { isUk ? "Нова категорія" : "New Category" }
        public static var modalEditTitle: String { isUk ? "Редагувати категорію" : "Edit Category" }
        public static var modalTitle: String { isUk ? "Нова транзакція" : "New Transaction" }
        public static var typeExpense: String { isUk ? "Витрата" : "Expense" }
        public static var typeIncome: String { isUk ? "Дохід" : "Income" }
        public static var typeTransfer: String { isUk ? "Переказ" : "Transfer" }
        public static var searchPlaceholder: String { isUk ? "Пошук за отримувачем чи описом..." : "Search by payee or description..." }
        public static var allTypes: String { isUk ? "Усі типи" : "All Types" }
        public static var allCategories: String { isUk ? "Усі категорії" : "All Categories" }
        public static var allAccounts: String { isUk ? "Усі рахунки" : "All Accounts" }
        public static var allAccountsTotal: String { isUk ? "Всього (Всі рахунки)" : "Total (All Accounts)" }
        public static var noTransactions: String { isUk ? "Не знайдено транзакцій за вказаними фільтрами." : "No transactions found matching your criteria." }
        public static var noTransactionsFound: String { isUk ? "Транзакцій не знайдено" : "No transactions found" }
        public static var resetFilters: String { isUk ? "Скинути фільтри" : "Reset Filters" }
        public static var resetAll: String { isUk ? "Скинути все" : "Reset All" }
        public static var applyFilters: String { isUk ? "Застосувати фільтри" : "Apply Filters" }
        public static var filters: String { isUk ? "Фільтри" : "Filters" }
        public static var loadMore: String { isUk ? "Завантажити ще" : "Load More" }
        public static var deleteTransaction: String { isUk ? "Видалити транзакцію" : "Delete Transaction" }
        public static var deleteConfirm: String { isUk ? "Ви впевнені, що хочете видалити цю транзакцію?" : "Are you sure you want to delete this transaction?" }
        public static var expenses: String { isUk ? "Витрати" : "Expenses" }
        public static var income: String { isUk ? "Доходи" : "Income" }
        public static var day: String { isUk ? "День" : "Day" }
        public static var week: String { isUk ? "Тиждень" : "Week" }
        public static var month: String { isUk ? "Місяць" : "Month" }
        public static var year: String { isUk ? "Рік" : "Year" }
        public static var period: String { isUk ? "Період" : "Period" }
        public static var breakdownView: String { isUk ? "Розподіл" : "Breakdown" }
        public static var historyView: String { isUk ? "Історія" : "History" }
        public static var selectCustomPeriod: String { isUk ? "Обрати власний період" : "Select Custom Period" }
        public static var fromDate: String { isUk ? "З дати" : "From Date" }
        public static var toDate: String { isUk ? "По дату" : "To Date" }
        public static var selectStartDate: String { isUk ? "Оберіть початкову дату" : "Select Start Date" }
        public static var selectEndDate: String { isUk ? "Оберіть кінцеву дату" : "Select End Date" }
        public static var dateRange: String { isUk ? "Діапазон дат" : "Date Range" }
        public static var noCategoryActivity: String { isUk ? "Немає активності за категоріями у цьому періоді." : "No category activity for this period." }
        public static var sourceAccount: String { isUk ? "Рахунок відправлення" : "Source Account" }
        public static var sourceSubAccount: String { isUk ? "Субрахунок відправлення" : "Source Sub-Account" }
        public static var destAccount: String { isUk ? "Рахунок призначення" : "Destination Account" }
        public static var destSubAccount: String { isUk ? "Субрахунок призначення" : "Destination Sub-Account" }
        public static var selectAccount: String { isUk ? "Оберіть рахунок" : "Select Account" }
        public static var selectSubAccount: String { isUk ? "Оберіть субрахунок" : "Select Sub-Account" }
        public static var noSubAccount: String { isUk ? "Без субрахунку (Основний)" : "No sub-account (Main)" }
        public static var commentOptional: String { isUk ? "Коментар або опис (необов'язково)" : "Comment or description (optional)" }
        public static var commentPlaceholder: String { isUk ? "Наприклад: комунальні, продукти..." : "e.g. Lunch with friends, groceries..." }
        public static var add: String { isUk ? "Додати" : "Add" }
        public static var selectCategory: String { isUk ? "Категорія" : "Category" }
        public static var today: String { isUk ? "Сьогодні" : "Today" }
        public static var yesterday: String { isUk ? "Вчора" : "Yesterday" }
        public static var custom: String { isUk ? "Власний" : "Custom" }
        public static var transferDescDefault: String { isUk ? "Переказ коштів" : "Funds Transfer" }

        public static func totalCountSubtitle(count: Int) -> String {
            if isUk {
                return "\(count) транзакцій"
            } else {
                return "\(count) transactions"
            }
        }
    }

    // MARK: - Savings Goals
    public enum Savings {
        public static var title: String { isUk ? "Цілі заощаджень" : "Savings Goals" }
        public static var subtitle: String { isUk ? "Встановлюйте фінансові цілі, призначайте субрахунки та відстежуйте прогрес." : "Set financial milestones, assign sub-accounts, and track your progress." }
        public static var newGoal: String { isUk ? "Нова ціль" : "New Goal" }
        public static var emptyTitle: String { isUk ? "Цілей заощаджень ще немає" : "No savings goals yet" }
        public static var emptySubtitle: String { isUk ? "Почніть втілювати свої мрії, створивши першу фінансову ціль." : "Start working towards your dreams by creating a savings goal." }
        public static var createFirstGoal: String { isUk ? "Створити першу ціль" : "Create Your First Goal" }
        public static var target: String { isUk ? "Ціль" : "Target" }
        public static var saved: String { isUk ? "Накопичено" : "Saved" }
        public static var remaining: String { isUk ? "Залишилось" : "Remaining" }
        public static var targetDate: String { isUk ? "Цільова дата" : "Target Date" }
        public static var targetAmountOptional: String { isUk ? "Цільова сума (необов'язково)" : "Target Amount (optional)" }
        public static var openGoal: String { isUk ? "Безстрокова ціль" : "Open Target" }
        public static var statusInProgress: String { isUk ? "У процесі" : "In Progress" }
        public static var statusCompleted: String { isUk ? "Досягнуто" : "Completed" }
        public static var contribute: String { isUk ? "Поповнити" : "Contribute" }
        public static var contributeToGoal: String { isUk ? "Поповнити ціль" : "Contribute to Goal" }
        public static var manage: String { isUk ? "Керувати" : "Manage" }
        public static var manageAllocations: String { isUk ? "Розподіл активів" : "Allocations & History" }
        public static var allocatedAssets: String { isUk ? "Активи та інвестиції" : "Assets & Holdings" }
        public static var cashBalance: String { isUk ? "Грошовий залишок" : "Cash Balance" }
        public static var cashDeposit: String { isUk ? "Грошовий депозит" : "Cash Deposit" }
        public static var withdrawCash: String { isUk ? "Зняти кошти" : "Withdraw" }
        public static var withdrawAmount: String { isUk ? "Сума зняття" : "Withdraw Amount" }
        public static var withdrawFromGoal: String { isUk ? "Зняти з цілі" : "Withdraw from Goal" }
        public static var totalSavingsProgress: String { isUk ? "Загальний прогрес заощаджень" : "Total Savings Progress" }
        public static var editGoal: String { isUk ? "Редагувати ціль" : "Edit Goal" }
        public static var deleteGoal: String { isUk ? "Видалити ціль" : "Delete Goal" }
        public static var modalCreateTitle: String { isUk ? "Нова ціль заощаджень" : "New Savings Goal" }
        public static var modalEditTitle: String { isUk ? "Редагувати ціль заощаджень" : "Edit Savings Goal" }
        public static var goalName: String { isUk ? "Назва цілі" : "Goal Name" }
        public static var goalNamePlaceholder: String { isUk ? "напр., Резервний фонд, Авто..." : "e.g. Emergency Fund, New Car..." }
        public static var deadline: String { isUk ? "Кінцевий термін (РРРР-ММ-ДД)" : "Deadline (YYYY-MM-DD)" }
        public static var optionalTargetDate: String { isUk ? "Орієнтовна дата" : "Optional target date" }
        public static var optionalDescription: String { isUk ? "Опис (необов'язково)" : "Optional description" }
        public static var preset: String { isUk ? "Шаблон:" : "Preset:" }
        public static var tabAllocations: String { isUk ? "Розподіл" : "Allocations" }
        public static var tabHistory: String { isUk ? "Історія" : "History" }
        public static var tabWithdraw: String { isUk ? "Зняття" : "Withdraw" }
        public static var noAllocationsInGoal: String { isUk ? "У цій цілі немає розподілених активів" : "No stock or crypto allocations in this goal" }
        public static var noContributionsYet: String { isUk ? "Поповнень поки немає" : "No contributions recorded yet" }
        public static var withdrawReasonPlaceholder: String { isUk ? "напр., Витрати на відпустку..." : "e.g. Vacation expenses..." }

        public static func savedOf(current: String, target: String) -> String {
            isUk ? "Накопичено \(current) з \(target)" : "Saved \(current) of \(target)"
        }

        public static func goalsSummary(count: Int, totalSaved: String) -> String {
            if isUk {
                return "\(count) цілей • Накопичено: \(totalSaved)"
            } else {
                return "\(count) goals • Saved: \(totalSaved)"
            }
        }

        public static func deleteConfirmMsg(name: String) -> String {
            isUk ? "Ви впевнені, що хочете видалити ціль '\(name)'?" : "Are you sure you want to delete '\(name)'?"
        }
    }

    // MARK: - Assets & Trading
    public enum Assets {
        public static var addAssetTitle: String { isUk ? "Додати інвестиційний актив" : "Add Investment Asset" }
        public static var buy: String { isUk ? "Купити" : "Buy" }
        public static var sell: String { isUk ? "Продати" : "Sell" }
        public static var stock: String { isUk ? "Акція / ETF" : "Stock / ETF" }
        public static var crypto: String { isUk ? "Криптовалюта" : "Crypto" }
        public static var assetType: String { isUk ? "Тип активу" : "Asset Type" }
        public static var symbol: String { isUk ? "Тикер активу" : "Symbol" }
        public static var searchAsset: String { isUk ? "Пошук активу" : "Search Asset" }
        public static var quote: String { isUk ? "Котирування" : "Quote" }
        public static var usePrice: String { isUk ? "Застосувати ціну" : "Use Price" }
        public static var quantity: String { isUk ? "Кількість" : "Quantity" }
        public static var pricePerUnit: String { isUk ? "Ціна за одиницю" : "Price / Unit" }
        public static var fee: String { isUk ? "Комісія" : "Fee" }
        public static var totalCost: String { isUk ? "Загальна сума:" : "Total Cost:" }
        public static var itemValue: String { isUk ? "Вартість позиції:" : "Item Value:" }
        public static var destinationAccount: String { isUk ? "Цільовий рахунок" : "Destination Account" }
        public static var destinationSubAccount: String { isUk ? "Субрахунок (Портфель)" : "Sub-Account (Portfolio)" }
        public static var notesOptional: String { isUk ? "Примітки (необов'язково)" : "Notes (optional)" }
        public static var notesPlaceholder: String { isUk ? "Примітки до угоди..." : "Trade notes or strategy..." }
        public static var cashAmount: String { isUk ? "Сума готівки" : "Cash Amount" }
        public static var quickAssets: String { isUk ? "Популярні активи" : "Popular Assets" }
    }

    // MARK: - Analytics
    public enum Analytics {
        public static var title: String { isUk ? "Фінансова аналітика" : "Analytics" }
        public static var netWorth: String { isUk ? "Капітал" : "Net Worth" }
        public static var totalAssets: String { isUk ? "Усі активи" : "Total Assets" }
        public static var liabilities: String { isUk ? "Зобов'язання" : "Liabilities" }
        public static var subtitle: String { isUk ? "Глибокий аналіз доходів, витрат, динаміки капіталу та активів." : "Deep dive into your budgets, spending behaviors, and portfolios." }
        public static var tabCashFlow: String { isUk ? "Грошовий потік" : "Cash Flow" }
        public static var tabNetWorth: String { isUk ? "Капітал та активи" : "Net Worth" }
        public static var totalIncome: String { isUk ? "Загальний дохід" : "Total Income" }
        public static var totalExpenses: String { isUk ? "Загальні витрати" : "Total Expenses" }
        public static var netCashFlow: String { isUk ? "Чистий потік" : "Net Cash Flow" }
        public static var savingsRate: String { isUk ? "Норма заощаджень" : "Savings Rate" }
        public static var expenseRatio: String { isUk ? "Коефіцієнт витрат" : "Expense Ratio" }
        public static var totalNetWorth: String { isUk ? "Загальний капітал" : "Total Net Worth" }
        public static var liquidAssets: String { isUk ? "Ліквідні активи" : "Liquid Assets" }
        public static var investments: String { isUk ? "Інвестиції" : "Investments" }
        public static var monthlyCashFlow: String { isUk ? "Щомісячний рух коштів" : "Monthly Cash Flow" }
        public static var expensesByCategory: String { isUk ? "Витрати за категоріями" : "Expenses by Category" }
        public static var incomeByCategory: String { isUk ? "Доходи за категоріями" : "Income by Category" }
        public static var topSpending: String { isUk ? "Найбільші витрати" : "Top Spending" }
        public static var assetAllocation: String { isUk ? "Розподіл активів" : "Asset Allocation" }
        public static var investmentHoldings: String { isUk ? "Інвестиційні активи" : "Investment Holdings" }
        public static var accountBreakdown: String { isUk ? "Структура за рахунками" : "Account Breakdown" }
        public static var selectDateRange: String { isUk ? "Виберіть діапазон дат" : "Select Date Range" }
        public static var allTime: String { isUk ? "Весь час" : "All Time" }
        public static var noDataRecorded: String { isUk ? "Дані відсутні" : "No data recorded" }

        public static func fromFormatted(_ formatted: String) -> String {
            isUk ? "З \(formatted)" : "From \(formatted)"
        }

        public static func untilFormatted(_ formatted: String) -> String {
            isUk ? "По \(formatted)" : "Until \(formatted)"
        }
    }

    // MARK: - Date Range Presets
    public enum DateRange {
        public static var allTime: String { isUk ? "Весь час" : "All Time" }
        public static var all: String { isUk ? "Всі" : "All" }
        public static var today: String { isUk ? "Сьогодні" : "Today" }
        public static var yesterday: String { isUk ? "Вчора" : "Yesterday" }
        public static var last7Days: String { isUk ? "Останні 7 днів" : "Last 7 Days" }
        public static var last30Days: String { isUk ? "Останні 30 днів" : "Last 30 Days" }
        public static var thisWeek: String { isUk ? "Цей тиждень" : "This Week" }
        public static var thisMonth: String { isUk ? "Цей місяць" : "This Month" }
        public static var thisYear: String { isUk ? "Цей рік" : "This Year" }
        public static var custom: String { isUk ? "Власний" : "Custom" }
    }

    // MARK: - Profile & Settings
    public enum Profile {
        public static var title: String { isUk ? "Профіль та налаштування" : "Profile & Settings" }
        public static var subtitle: String { isUk ? "Керуйте своїми особистими даними, основною валютою та мовою інтерфейсу." : "Manage your personal details, primary base currency, and application language." }
        public static var personalInfo: String { isUk ? "Особисті дані" : "Personal Information" }
        public static var firstName: String { isUk ? "Ім'я" : "First Name" }
        public static var lastName: String { isUk ? "Прізвище" : "Last Name" }
        public static var email: String { isUk ? "Електронна пошта" : "Email" }
        public static var primaryCurrency: String { isUk ? "Основна базова валюта" : "Primary Base Currency" }
        public static var primaryCurrencyDesc: String { isUk ? "Ця валюта використовується для підрахунку загального балансу, графіків та аналітики." : "This currency is used to aggregate total balances, net worth charts, and analytics across all your accounts." }
        public static var interfaceLanguage: String { isUk ? "Мова інтерфейсу" : "Interface Language" }
        public static var english: String { isUk ? "Англійська" : "English" }
        public static var ukrainian: String { isUk ? "Українська" : "Ukrainian" }
        public static var apiServerTarget: String { isUk ? "Сервер API" : "API Server Target" }
        public static var localhost: String { isUk ? "Локальний (:5237)" : "Localhost (:5237)" }
        public static var cloudApi: String { isUk ? "Хмарний API" : "Cloud API" }
        public static var saveChanges: String { isUk ? "Зберегти зміни" : "Save Changes" }
        public static var savingChanges: String { isUk ? "Збереження змін..." : "Saving Changes..." }
        public static var logOut: String { isUk ? "Вийти" : "Log Out" }
        public static var logOutConfirmTitle: String { isUk ? "Вийти з акаунта" : "Log Out" }
        public static var logOutConfirmMsg: String { isUk ? "Ви впевнені, що хочете вийти зі свого акаунта?" : "Are you sure you want to log out of your account?" }
        public static var profileUpdated: String { isUk ? "Профіль успішно оновлено!" : "Profile updated successfully!" }
    }

    // MARK: - Language
    public enum Language {
        public static var language: String { isUk ? "Мова" : "Language" }
        public static var english: String { "English" }
        public static var ukrainian: String { "Українська" }
    }
}
