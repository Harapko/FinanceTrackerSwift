import SwiftUI

struct SavingsGoalCardView: View {
    let goal: SavingsGoalResponse
    let onEdit: () -> Void
    let onContribute: () -> Void

    var accentColor: Color {
        Color(hex: goal.color ?? "818cf8")
    }

    var progressPercent: Double {
        goal.targetAmount > 0 ? min(goal.currentAmount / goal.targetAmount, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text(goal.icon ?? "🎯")
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.name)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        if goal.isCompleted {
                            Text("✓ Completed")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(hex: "34d399"))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color(hex: "34d399").opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    if let acc = goal.accountName {
                        Text(acc)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }

                Spacer()

                Menu {
                    Button("Edit Goal", systemImage: "pencil") { onEdit() }
                    Button("Contribute", systemImage: "plus.circle") { onContribute() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.currentAmount.formatted(currencyCode: goal.currencyCode))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("of \(goal.targetAmount.formatted(currencyCode: goal.currencyCode))")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.5))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [accentColor, accentColor.opacity(0.7)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progressPercent, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(String(format: "%.1f%% complete", progressPercent * 100))
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                    Spacer()
                    if let deadline = goal.deadline {
                        Label(deadline, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
            }

            // Contribute button
            if !goal.isCompleted {
                Button {
                    onContribute()
                } label: {
                    Label("Contribute", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [accentColor, accentColor.opacity(0.7)],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}
