import Foundation
import Combine

// MARK: - AddTransactionViewModel

@MainActor
final class AddTransactionViewModel: ObservableObject {

    // MARK: - Form State

    @Published var title: String = ""
    @Published var amountText: String = ""
    @Published var selectedType: TransactionType = .expense
    @Published var selectedCategory: Category = .other
    @Published var date: Date = Date()
    @Published var note: String = ""

    // MARK: - Validation

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedAmount != nil
    }

    var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var validationMessage: String {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter a title."
        }
        if parsedAmount == nil {
            return "Please enter a valid amount."
        }
        return ""
    }

    // MARK: - Build Domain Model

    func buildTransaction() -> Transaction? {
        guard let amount = parsedAmount, isValid else { return nil }
        return Transaction(
            title:    title.trimmingCharacters(in: .whitespaces),
            amount:   amount,
            type:     selectedType,
            category: selectedCategory,
            date:     date,
            note:     note.isEmpty ? nil : note
        )
    }

    // MARK: - Reset

    func reset() {
        title = ""
        amountText = ""
        selectedType = .expense
        selectedCategory = .other
        date = Date()
        note = ""
    }
}
