import Foundation

// MARK: - Category

enum Category: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transport = "Transport"
    case shopping = "Shopping"
    case health = "Health"
    case entertainment = "Entertainment"
    case housing = "Housing"
    case income = "Income"
    case other = "Other"

    var emoji: String {
        switch self {
        case .food:          return "🍔"
        case .transport:     return "🚌"
        case .shopping:      return "🛍"
        case .health:        return "💊"
        case .entertainment: return "🎬"
        case .housing:       return "🏠"
        case .income:        return "💼"
        case .other:         return "📦"
        }
    }
}

// MARK: - TransactionType

enum TransactionType: String, Codable {
    case income
    case expense
}

// MARK: - Transaction

struct Transaction: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var category: Category
    var date: Date
    var note: String?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        category: Category,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.note = note
    }
}

// MARK: - MonthlySummary

struct MonthlySummary {
    let totalIncome: Double
    let totalExpenses: Double

    var balance: Double { totalIncome - totalExpenses }

    var balanceIsPositive: Bool { balance >= 0 }
}
