import SwiftUI

struct AddSavingsGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let editingGoal: SavingsGoalResponse?
    let onSuccess: () -> Void

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var currencyCode = "USD"
    @State private var deadline = ""
    @State private var description = ""
    @State private var icon = "🎯"
    @State private var color = "#818cf8"
    @State private var isLoading = false
    @State private var errorMessage: String?

    let iconOptions = ["🎯", "🏠", "✈️", "🚗", "📚", "💪", "🎸", "💍", "🌴", "💻"]
    let colorOptions = ["#818cf8", "#a78bfa", "#f472b6", "#34d399", "#fbbf24", "#60a5fa", "#fb923c", "#e879f9"]
    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "AUD"]

    var isEditing: Bool { editingGoal != nil }
    var title: String { isEditing ? "Edit Goal" : "New Savings Goal" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Icon picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Goal Icon").font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(iconOptions, id: \.self) { i in
                                        Text(i)
                                            .font(.title2)
                                            .padding(10)
                                            .background(icon == i ? Color(hex: "818cf8").opacity(0.3) : Color.white.opacity(0.07))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(icon == i ? Color(hex: "818cf8") : Color.clear, lineWidth: 2))
                                            .onTapGesture { icon = i }
                                    }
                                }
                            }
                        }

                        // Color
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Accent Color").font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
                            HStack(spacing: 10) {
                                ForEach(colorOptions, id: \.self) { c in
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 30, height: 30)
                                        .overlay(Circle().stroke(Color.white, lineWidth: color == c ? 3 : 0))
                                        .onTapGesture { color = c }
                                }
                            }
                        }

                        formField("Goal Name", icon: "target") { TextField("e.g. Emergency Fund", text: $name) }

                        formField("Target Amount", icon: "dollarsign.circle") {
                            TextField("0.00", text: $targetAmount).keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Currency", systemImage: "dollarsign.circle").font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
                            Picker("Currency", selection: $currencyCode) {
                                ForEach(currencies, id: \.self) { c in Text(c).tag(c) }
                            }
                            .pickerStyle(.menu).padding(12).background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
                        }

                        formField("Deadline (YYYY-MM-DD)", icon: "calendar") { TextField("Optional", text: $deadline) }
                        formField("Description", icon: "text.alignleft") { TextField("Optional", text: $description) }

                        if let error = errorMessage {
                            Text(error).font(.caption).foregroundColor(Color(hex: "f87171"))
                                .padding(12).background(Color(hex: "f87171").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Text(isEditing ? "Save Changes" : "Create Goal").font(.headline).foregroundColor(.white) }
                            }
                            .frame(maxWidth: .infinity).padding(16)
                            .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || name.isEmpty || targetAmount.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
        .onAppear {
            if let g = editingGoal {
                name = g.name
                targetAmount = String(g.targetAmount)
                currencyCode = g.currencyCode
                deadline = g.deadline ?? ""
                description = g.description ?? ""
                icon = g.icon ?? "🎯"
                color = g.color ?? "#818cf8"
            }
        }
    }

    private func save() async {
        guard let amount = Double(targetAmount) else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            if let g = editingGoal {
                let payload = UpdateSavingsGoalPayload(name: name, targetAmount: amount, currencyCode: currencyCode,
                    deadline: deadline.isEmpty ? nil : deadline, description: description.isEmpty ? nil : description,
                    icon: icon, color: color, accountId: nil, subAccountId: nil)
                let _: SavingsGoalResponse = try await SavingsGoalService.shared.updateGoal(id: g.id, payload: payload)
            } else {
                let payload = CreateSavingsGoalPayload(name: name, targetAmount: amount, currencyCode: currencyCode,
                    deadline: deadline.isEmpty ? nil : deadline, description: description.isEmpty ? nil : description,
                    icon: icon, color: color, accountId: nil, subAccountId: nil)
                let _: SavingsGoalResponse = try await SavingsGoalService.shared.createGoal(payload)
            }
            onSuccess(); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    @ViewBuilder
    private func formField<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon).font(.caption.weight(.semibold)).foregroundColor(Color.white.opacity(0.6))
            content().textFieldStyle(.plain).padding(14).background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
        }
    }
}
