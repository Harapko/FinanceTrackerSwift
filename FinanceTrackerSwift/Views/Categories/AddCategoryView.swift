import SwiftUI

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    var initialType: CategoryTypeOption = .expense
    var onSuccess: (CategoryResponse) -> Void = { _ in }

    @State private var name: String = ""
    @State private var type: CategoryTypeOption = .expense
    @State private var selectedIcon: String = "bag.fill"
    @State private var selectedColor: String = "818cf8"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let availableIcons: [String] = [
        "bag.fill",
        "cart.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "house.fill",
        "car.fill",
        "heart.fill",
        "briefcase.fill",
        "graduationcap.fill",
        "gift.fill",
        "airplane",
        "film.fill",
        "music.note",
        "dumbbell.fill",
        "cross.case.fill",
        "creditcard.fill",
        "banknote.fill",
        "chart.line.uptrend.xyaxis",
        "wrench.and.screwdriver.fill",
        "sparkles"
    ]

    let colorOptions: [String] = [
        "f43f5e", // Rose
        "ef4444", // Red
        "f97316", // Orange
        "fbbf24", // Amber
        "10b981", // Green
        "34d399", // Emerald
        "06b6d4", // Cyan
        "3b82f6", // Blue
        "818cf8", // Indigo
        "a855f7", // Purple
        "ec4899", // Pink
        "64748b"  // Slate
    ]

    var themeColor: Color {
        Color(hex: selectedColor)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // 1. Type Segmented Control
                        HStack(spacing: 4) {
                            ForEach(CategoryTypeOption.allCases, id: \.self) { opt in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        type = opt
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: opt.icon)
                                            .font(.caption.bold())
                                        Text(opt.displayName)
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundColor(type == opt ? .white : Color.white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        type == opt ?
                                        LinearGradient(
                                            colors: [themeColor.opacity(0.8), themeColor],
                                            startPoint: .leading, endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.clear, Color.clear],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // 2. Live Preview Badge
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(themeColor.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .stroke(themeColor.opacity(0.5), lineWidth: 2)
                                    )
                                    .shadow(color: themeColor.opacity(0.4), radius: 10)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(themeColor)
                            }

                            Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Category Preview" : name)
                                .font(.headline.bold())
                                .foregroundColor(.white)

                            Text(type.displayName)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // 3. Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category Name", systemImage: "tag.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            TextField("e.g. Groceries, Coffee, Freelance...", text: $name)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }

                        // 4. Color Palette
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Theme Color", systemImage: "paintpalette.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                                ForEach(colorOptions, id: \.self) { c in
                                    let isSelected = selectedColor.lowercased() == c.lowercased()
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                        )
                                        .shadow(color: isSelected ? Color(hex: c).opacity(0.6) : Color.clear, radius: 6)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedColor = c
                                            }
                                        }
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // 5. Icon Grid Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Icon", systemImage: "square.grid.3x3.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 46))], spacing: 10) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    let isSelected = selectedIcon == icon
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedIcon = icon
                                        }
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isSelected ? themeColor.opacity(0.25) : Color.white.opacity(0.04))
                                                .frame(height: 46)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(isSelected ? themeColor : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                                                )

                                            Image(systemName: icon)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(isSelected ? themeColor : Color.white.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(12)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Save Button
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Category")
                                            .font(.headline.bold())
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [themeColor.opacity(0.9), themeColor],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: themeColor.opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .onAppear {
                type = initialType
                if initialType == .income {
                    selectedColor = "10b981"
                }
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = CreateCategoryPayload(
            name: trimmedName,
            type: type.rawValue,
            parentCategoryId: nil,
            icon: selectedIcon,
            color: selectedColor
        )

        do {
            let created = try await CategoryService.shared.createCategory(payload)
            onSuccess(created)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
