import SwiftUI

struct ContributeToGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoalResponse
    let onSuccess: () -> Void

    @State private var amount = ""
    @State private var note = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()
                VStack(spacing: 24) {
                    // Goal summary
                    VStack(spacing: 8) {
                        Text(goal.icon ?? "🎯").font(.system(size: 52))
                        Text(goal.name).font(.title2.bold()).foregroundColor(.white)
                        Text("\(goal.currentAmount.formatted(currencyCode: goal.currencyCode)) / \(goal.targetAmount.formatted(currencyCode: goal.currencyCode))")
                            .font(.subheadline).foregroundColor(Color.white.opacity(0.5))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [Color(hex: goal.color ?? "818cf8"), Color(hex: "a78bfa")],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * goal.progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Contribution Amount", systemImage: "dollarsign.circle")
                                .font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain).padding(14)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white).font(.title3.bold())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note (optional)", systemImage: "note.text")
                                .font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
                            TextField("What is this for?", text: $note)
                                .textFieldStyle(.plain).padding(14)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                        }

                        if let error = errorMessage {
                            Text(error).font(.caption).foregroundColor(Color(hex: "f87171"))
                                .padding(12).background(Color(hex: "f87171").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task { await contribute() }
                        } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Label("Contribute", systemImage: "plus.circle.fill").font(.headline).foregroundColor(.white) }
                            }
                            .frame(maxWidth: .infinity).padding(16)
                            .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || amount.isEmpty)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Contribute to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
    }

    private func contribute() async {
        guard let amountDouble = Double(amount) else { return }
        let payload = ContributeSavingsGoalPayload(amount: amountDouble, note: note.isEmpty ? nil : note)
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let _: SavingsGoalResponse = try await SavingsGoalService.shared.contribute(goalId: goal.id, payload: payload)
            onSuccess(); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
