import Foundation
import CoreData

// MARK: - Protocol (enables mocking in unit tests)

protocol PersistenceServiceProtocol {
    func fetchTransactions() async throws -> [Transaction]
    func save(transaction: Transaction) async throws
    func delete(transactionID: UUID) async throws
}

// MARK: - CoreDataService

final class CoreDataService: PersistenceServiceProtocol {

    // MARK: - Core Data Stack

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpendTrack")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed to load: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private var context: NSManagedObjectContext { container.viewContext }

    // MARK: - Fetch

    func fetchTransactions() async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomain() }
        }
    }

    // MARK: - Save

    func save(transaction: Transaction) async throws {
        try await context.perform {
            let entity = TransactionEntity(context: self.context)
            entity.id       = transaction.id
            entity.title    = transaction.title
            entity.amount   = transaction.amount
            entity.type     = transaction.type.rawValue
            entity.category = transaction.category.rawValue
            entity.date     = transaction.date
            entity.note     = transaction.note
            try self.context.save()
        }
    }

    // MARK: - Delete

    func delete(transactionID: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
            request.predicate = NSPredicate(format: "id == %@", transactionID as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
}

// MARK: - NSManagedObject → Domain mapping

private extension TransactionEntity {
    func toDomain() -> Transaction? {
        guard
            let id       = id,
            let title    = title,
            let typeRaw  = type,
            let catRaw   = category,
            let date     = date,
            let type     = TransactionType(rawValue: typeRaw),
            let category = Category(rawValue: catRaw)
        else { return nil }

        return Transaction(
            id:       id,
            title:    title,
            amount:   amount,
            type:     type,
            category: category,
            date:     date,
            note:     note
        )
    }
}
