import SwiftUI

@Observable
class SavingsViewModel {
    var goals: [SavingsGoalResponse] = []
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }

    var totalTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }

    var overallProgress: Double {
        totalTarget > 0 ? min(totalSaved / totalTarget, 1.0) : 0
    }

    func load(isManualRefresh: Bool = false) async {
        if isManualRefresh {
            isRefreshing = true
        } else if goals.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        do {
            goals = try await SavingsGoalService.shared.getGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        withAnimation(.easeInOut(duration: 0.25)) {
            goals.removeAll { $0.id == id }
        }
        do {
            try await SavingsGoalService.shared.deleteGoal(id: id)
        } catch {
            errorMessage = error.localizedDescription
            await load()
        }
    }
}

enum SavingsModalSheet: Identifiable {
    case addGoal
    case editGoal(SavingsGoalResponse)
    case contribute(SavingsGoalResponse)
    case manageAllocations(goalId: String)

    var id: String {
        switch self {
        case .addGoal: return "addGoal"
        case .editGoal(let g): return "editGoal-\(g.id)"
        case .contribute(let g): return "contribute-\(g.id)"
        case .manageAllocations(let id): return "manageAllocations-\(id)"
        }
    }
}

struct SavingsView: View {
    @State private var viewModel = SavingsViewModel()
    @State private var activeSheet: SavingsModalSheet? = nil
    @State private var goalToDelete: SavingsGoalResponse? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Savings.title)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text(L10n.Savings.goalsSummary(count: viewModel.goals.count, totalSaved: viewModel.totalSaved.formatted(currencyCode: "USD")))
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    Spacer()

                    Button {
                        activeSheet = .addGoal
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                            Text(L10n.Savings.newGoal)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(LinearGradient(
                            colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 4)

                // Error Banner
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error).font(.caption)
                    }
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(12)
                    .background(Color(hex: "f87171").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Overall Progress Card
                if !viewModel.goals.isEmpty && viewModel.totalTarget > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.Savings.totalSavingsProgress)
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color.white.opacity(0.6))
                            Spacer()
                            Text(String(format: "%.0f%%", viewModel.overallProgress * 100))
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "34d399"))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "34d399"), Color(hex: "818cf8")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * viewModel.overallProgress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text(viewModel.totalSaved.formatted(currencyCode: "USD"))
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(L10n.Savings.target): \(viewModel.totalTarget.formatted(currencyCode: "USD"))")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Goals List
                if viewModel.isLoading && viewModel.goals.isEmpty {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.goals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text(L10n.Savings.emptyTitle)
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.4))
                        Button(L10n.Savings.createFirstGoal) {
                            activeSheet = .addGoal
                        }
                        .foregroundColor(Color(hex: "a78bfa"))
                        .font(.subheadline.bold())
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.goals) { goal in
                            SavingsGoalCardView(
                                goal: goal,
                                onEdit: {
                                    activeSheet = .editGoal(goal)
                                },
                                onContribute: {
                                    activeSheet = .contribute(goal)
                                },
                                onManageAllocations: {
                                    activeSheet = .manageAllocations(goalId: goal.id)
                                },
                                onDelete: {
                                    goalToDelete = goal
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .refreshable {
            await viewModel.load(isManualRefresh: true)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addGoal:
                AddSavingsGoalView {
                    Task { await viewModel.load() }
                }
            case .editGoal(let goal):
                AddSavingsGoalView(editingGoal: goal) {
                    Task { await viewModel.load() }
                }
            case .contribute(let goal):
                ContributeToGoalView(goal: goal) {
                    Task { await viewModel.load() }
                }
            case .manageAllocations(let goalId):
                ManageGoalAllocationsView(goalId: goalId) {
                    Task { await viewModel.load() }
                }
            }
        }
        .confirmationDialog(
            L10n.Savings.deleteGoal,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Savings.deleteGoal, role: .destructive) {
                if let g = goalToDelete {
                    Task { await viewModel.delete(id: g.id) }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            if let g = goalToDelete {
                Text(L10n.Savings.deleteConfirmMsg(name: g.name))
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
