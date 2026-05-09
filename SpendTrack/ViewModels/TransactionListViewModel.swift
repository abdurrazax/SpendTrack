import Foundation
import Combine

// MARK: - TransactionListViewModel

@MainActor
final class TransactionListViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var summary: MonthlySummary = MonthlySummary(totalIncome: 0, totalExpenses: 0)
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies (injected via protocol — fully testable)

    private let persistenceService: PersistenceServiceProtocol

    // MARK: - Init

    init(persistenceService: PersistenceServiceProtocol = CoreDataService()) {
        self.persistenceService = persistenceService
    }

    // MARK: - Intent

    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        do {
            transactions = try await persistenceService.fetchTransactions()
            summary = calculateSummary(from: transactions)
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addTransaction(_ transaction: Transaction) async {
        do {
            try await persistenceService.save(transaction: transaction)
            await loadTransactions()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func deleteTransaction(id: UUID) async {
        do {
            try await persistenceService.delete(transactionID: id)
            transactions.removeAll { $0.id == id }
            summary = calculateSummary(from: transactions)
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    // MARK: - Filtering

    func transactions(for category: Category) -> [Transaction] {
        transactions.filter { $0.category == category }
    }

    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    // MARK: - Private Helpers

    private func calculateSummary(from transactions: [Transaction]) -> MonthlySummary {
        let calendar = Calendar.current
        let now = Date()
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let income   = monthTransactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
        let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return MonthlySummary(totalIncome: income, totalExpenses: expenses)
    }
}
