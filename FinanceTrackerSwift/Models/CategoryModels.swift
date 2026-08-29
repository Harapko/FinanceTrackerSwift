import Foundation

enum CategoryTypeOption: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case both = "Both"

    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .both: return "Both"
        }
    }

    var icon: String {
        switch self {
        case .expense: return "arrow.down.right.circle.fill"
        case .income: return "arrow.up.right.circle.fill"
        case .both: return "arrow.up.arrow.down.circle.fill"
        }
    }
}

struct CategoryResponse: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String?
    let color: String?
    let icon: String?
    let isSystem: Bool?
    let parentCategoryId: String?
    let sortOrder: Int?

    var displayIcon: String {
        guard let icon = icon, !icon.isEmpty else {
            return "tag.fill"
        }
        return icon
    }

    var displayColor: String {
        guard let color = color, !color.isEmpty else {
            return "818cf8"
        }
        return color.replacingOccurrences(of: "#", with: "")
    }
}

struct CreateCategoryPayload: Encodable {
    let name: String
    let type: String
    let parentCategoryId: String?
    let icon: String?
    let color: String?

    init(
        name: String,
        type: String,
        parentCategoryId: String? = nil,
        icon: String? = nil,
        color: String? = nil
    ) {
        self.name = name
        self.type = type
        self.parentCategoryId = parentCategoryId
        self.icon = icon
        self.color = color
    }
}
