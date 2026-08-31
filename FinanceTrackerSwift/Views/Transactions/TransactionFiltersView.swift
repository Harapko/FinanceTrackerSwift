import SwiftUI

enum DateFilterPreset: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case thisYear = "This Year"
    case custom = "Custom"

    var displayName: String {
        switch self {
        case .all: return L10n.DateRange.allTime
        case .today: return L10n.DateRange.today
        case .thisWeek: return L10n.DateRange.thisWeek
        case .thisMonth: return L10n.DateRange.thisMonth
        case .last30Days: return L10n.DateRange.last30Days
        case .thisYear: return L10n.DateRange.thisYear
        case .custom: return L10n.DateRange.custom
        }
    }
}

struct TransactionFiltersView: View {
    @Bindable var viewModel: TransactionsViewModel
    let onApply: () -> Void

    @State private var selectedPreset: DateFilterPreset = .all
    @State private var fromDateVal: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDateVal: Date = Date()
    @State private var showFromDatePicker = false
    @State private var showToDatePicker = false

    private let apiFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var displayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = LocalizationManager.shared.currentLocale
        f.dateFormat = "MMM d, yyyy"
        return f
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.4))
                TextField(L10n.Transactions.searchPlaceholder, text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 2. Type Selector Pills
            HStack(spacing: 8) {
                typeFilterPill(title: L10n.Transactions.allTypes, typeValue: "")
                typeFilterPill(title: L10n.Transactions.typeExpense, typeValue: "Expense", activeColor: Color(hex: "f87171"))
                typeFilterPill(title: L10n.Transactions.typeIncome, typeValue: "Income", activeColor: Color(hex: "34d399"))
                typeFilterPill(title: L10n.Transactions.typeTransfer, typeValue: "Transfer", activeColor: Color(hex: "818cf8"))
            }

            // 3. Quick Date Range Presets Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateFilterPreset.allCases, id: \.self) { preset in
                        let isSelected = selectedPreset == preset
                        Button {
                            applyPreset(preset)
                        } label: {
                            Text(preset.displayName)
                                .font(.caption.weight(isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(isSelected ? Color(hex: "a78bfa") : Color.white.opacity(0.05))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color(hex: "a78bfa") : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // 4. Custom Date Range Pickers (From / To inputs)
            HStack(spacing: 12) {
                // From Date
                Button {
                    showFromDatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                        Text(viewModel.fromDate.isEmpty ? L10n.Transactions.fromDate : formattedDisplayDate(viewModel.fromDate))
                            .font(.caption.weight(.medium))
                            .foregroundColor(viewModel.fromDate.isEmpty ? Color.white.opacity(0.4) : .white)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(!viewModel.fromDate.isEmpty ? Color(hex: "a78bfa").opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }

                // To Date
                Button {
                    showToDatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                        Text(viewModel.toDate.isEmpty ? L10n.Transactions.toDate : formattedDisplayDate(viewModel.toDate))
                            .font(.caption.weight(.medium))
                            .foregroundColor(viewModel.toDate.isEmpty ? Color.white.opacity(0.4) : .white)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(!viewModel.toDate.isEmpty ? Color(hex: "a78bfa").opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
            }

            // 5. Actions Row (Apply / Reset)
            HStack(spacing: 12) {
                Button {
                    selectedPreset = .all
                    viewModel.reset()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(L10n.Transactions.resetAll)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onApply()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text(L10n.Transactions.applyFilters)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color(hex: "818cf8").opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "161b22"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .sheet(isPresented: $showFromDatePicker) {
            NavigationStack {
                DatePicker(L10n.Transactions.fromDate, selection: $fromDateVal, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle(L10n.Transactions.selectStartDate)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.Common.clear) {
                                viewModel.fromDate = ""
                                selectedPreset = .custom
                                showFromDatePicker = false
                            }
                            .foregroundColor(Color(hex: "f87171"))
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.Common.done) {
                                viewModel.fromDate = apiFormatter.string(from: fromDateVal)
                                selectedPreset = .custom
                                showFromDatePicker = false
                            }
                            .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showToDatePicker) {
            NavigationStack {
                DatePicker(L10n.Transactions.toDate, selection: $toDateVal, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle(L10n.Transactions.selectEndDate)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.Common.clear) {
                                viewModel.toDate = ""
                                selectedPreset = .custom
                                showToDatePicker = false
                            }
                            .foregroundColor(Color(hex: "f87171"))
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.Common.done) {
                                viewModel.toDate = apiFormatter.string(from: toDateVal)
                                selectedPreset = .custom
                                showToDatePicker = false
                            }
                            .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            syncPresetFromViewModel()
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func typeFilterPill(title: String, typeValue: String, activeColor: Color = Color(hex: "818cf8")) -> some View {
        let isSelected = viewModel.selectedType == typeValue
        Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.selectedType = typeValue
            }
        } label: {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? activeColor.opacity(0.8) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? activeColor : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private func formattedDisplayDate(_ dateStr: String) -> String {
        guard let d = apiFormatter.date(from: dateStr) else { return dateStr }
        return displayFormatter.string(from: d)
    }

    private func applyPreset(_ preset: DateFilterPreset) {
        selectedPreset = preset
        let cal = Calendar.current
        let today = Date()

        switch preset {
        case .all:
            viewModel.fromDate = ""
            viewModel.toDate = ""
        case .today:
            let str = apiFormatter.string(from: today)
            viewModel.fromDate = str
            viewModel.toDate = str
        case .thisWeek:
            let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            viewModel.fromDate = apiFormatter.string(from: startOfWeek)
            viewModel.toDate = apiFormatter.string(from: today)
        case .thisMonth:
            let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
            viewModel.fromDate = apiFormatter.string(from: startOfMonth)
            viewModel.toDate = apiFormatter.string(from: today)
        case .last30Days:
            let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: today) ?? today
            viewModel.fromDate = apiFormatter.string(from: thirtyDaysAgo)
            viewModel.toDate = apiFormatter.string(from: today)
        case .thisYear:
            let startOfYear = cal.date(from: cal.dateComponents([.year], from: today)) ?? today
            viewModel.fromDate = apiFormatter.string(from: startOfYear)
            viewModel.toDate = apiFormatter.string(from: today)
        case .custom:
            break
        }
    }

    private func syncPresetFromViewModel() {
        if viewModel.fromDate.isEmpty && viewModel.toDate.isEmpty {
            selectedPreset = .all
        } else {
            selectedPreset = .custom
            if let d = apiFormatter.date(from: viewModel.fromDate) {
                fromDateVal = d
            }
            if let d = apiFormatter.date(from: viewModel.toDate) {
                toDateVal = d
            }
        }
    }
}
