import SwiftUI

@Observable
class SavingsViewModel {
    var goals: [SavingsGoalResponse] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            goals = try await SavingsGoalService.shared.getGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await SavingsGoalService.shared.deleteGoal(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SavingsView: View {
    @State private var viewModel = SavingsViewModel()
    @State private var showAddGoal = false
    @State private var editingGoal: SavingsGoalResponse? = nil
    @State private var contributeGoal: SavingsGoalResponse? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Savings Goals")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("\(viewModel.goals.count) active goals")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Button { showAddGoal = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                            startPoint: .leading, endPoint: .trailing))
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 4)

                if viewModel.isLoading {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.goals.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "target").font(.system(size: 52)).foregroundColor(Color.white.opacity(0.2))
                        Text("No savings goals yet").font(.headline).foregroundColor(Color.white.opacity(0.4))
                        Text("Set a goal and track your progress toward it!")
                            .font(.subheadline).foregroundColor(Color.white.opacity(0.3)).multilineTextAlignment(.center)
                        Button("Create First Goal") { showAddGoal = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.goals) { goal in
                            SavingsGoalCardView(goal: goal) {
                                editingGoal = goal
                            } onContribute: {
                                contributeGoal = goal
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: goal.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .sheet(isPresented: $showAddGoal) {
            AddSavingsGoalView(editingGoal: nil) { Task { await viewModel.load() } }
        }
        .sheet(item: $editingGoal) { goal in
            AddSavingsGoalView(editingGoal: goal) { Task { await viewModel.load() } }
        }
        .sheet(item: $contributeGoal) { goal in
            ContributeToGoalView(goal: goal) { Task { await viewModel.load() } }
        }
        .task { await viewModel.load() }
    }
}
