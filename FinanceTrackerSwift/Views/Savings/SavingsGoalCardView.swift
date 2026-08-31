import SwiftUI

struct SavingsGoalCardView: View {
    let goal: SavingsGoalResponse
    var onEdit: () -> Void = {}
    var onContribute: () -> Void = {}
    var onManageAllocations: () -> Void = {}
    var onDelete: () -> Void = {}

    var accentColor: Color {
        Color(hex: goal.color ?? "818cf8")
    }

    var progressPercent: Double {
        goal.targetAmount > 0 ? min(goal.currentAmount / goal.targetAmount, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Icon, Name, Target, Menu
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 46, height: 46)
                    Text(goal.icon ?? "🎯")
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(goal.name)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if goal.isCompleted {
                            Text("✓ Done")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "34d399"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
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
                    Button {
                        onContribute()
                    } label: {
                        Label(L10n.Savings.contribute, systemImage: "plus.circle")
                    }

                    Button {
                        onManageAllocations()
                    } label: {
                        Label(L10n.Savings.manageAllocations, systemImage: "chart.pie")
                    }

                    Button {
                        onEdit()
                    } label: {
                        Label(L10n.Savings.editGoal, systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(L10n.Savings.deleteGoal, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
            }

            // Description if any
            if let desc = goal.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                    .italic()
            }

            // Saved Instruments / Stock & Crypto Allocation Badges
            if !goal.savedInstrumentsList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(L10n.Savings.allocatedAssets, systemImage: "chart.pie.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                        Spacer()
                        Button {
                            onManageAllocations()
                        } label: {
                            Text(L10n.Savings.manage)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(goal.savedInstrumentsList) { inst in
                                let isGain = (inst.unrealizedPnL ?? 0) >= 0
                                HStack(spacing: 6) {
                                    Text(inst.symbol)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)

                                    if let pnlPercent = inst.unrealizedPnLPercent {
                                        Text(String(format: "%+.1f%%", pnlPercent))
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(isGain ? Color(hex: "34d399") : Color(hex: "f87171"))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(goal.currentAmount.formatted(currencyCode: goal.currencyCode))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text(L10n.Savings.savedOf(current: goal.currentAmount.formatted(currencyCode: goal.currencyCode), target: goal.targetAmount > 0 ? goal.targetAmount.formatted(currencyCode: goal.currencyCode) : L10n.Savings.openGoal))
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    if goal.targetAmount > 0 {
                        Text(String(format: "%.0f%%", progressPercent * 100))
                            .font(.headline.bold())
                            .foregroundColor(accentColor)
                    }
                }

                if goal.targetAmount > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    colors: [accentColor, Color(hex: "a78bfa")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * progressPercent, height: 8)
                        }
                    }
                    .frame(height: 8)
                }

                if let deadline = goal.deadline {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("\(L10n.Savings.target): \(deadline)")
                            .font(.caption2)
                    }
                    .foregroundColor(Color.white.opacity(0.4))
                }
            }

            // Action Buttons Row
            HStack(spacing: 8) {
                Button {
                    onContribute()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text(L10n.Savings.contribute)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(LinearGradient(
                        colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onManageAllocations()
                } label: {
                    Image(systemName: "chart.pie")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "a78bfa"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "a78bfa").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.25), lineWidth: 1.5)
        )
    }
}
