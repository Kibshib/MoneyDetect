
import Foundation
import Combine

final class TransactionsService: ObservableObject {
    static let shared = TransactionsService()
    @Published private(set) var transactions: [Transaction] = [
        Transaction(
            id: 1,
            accountId: 1,
            categoryId: 2,
            amount: 350.00,
            transactionDate: Date(),
            comment: "Пицца",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 2,
            accountId: 1,
            categoryId: 1,
            amount: 30_000.00,
            transactionDate: Date(),
            comment: "Зарплата",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 3,
            accountId: 1,
            categoryId: 3,
            amount: 1_450.00,
            transactionDate: Date(),
            comment: "Магазин «Пятёрочка»",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 4,
            accountId: 1,
            categoryId: 4,
            amount: 55.00,
            transactionDate: Date(),
            comment: "Метро",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 5,
            accountId: 1,
            categoryId: 5,
            amount: 820.00,
            transactionDate: Date(),
            comment: "Starbucks",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 6,
            accountId: 1,
            categoryId: 1,
            amount: 30_000.00,
            transactionDate: ISO8601DateFormatter()
                .date(from: "2025-06-16T08:00:00Z")!,
            comment: "Бонус за проект",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 7,
            accountId: 1,
            categoryId: 6,
            amount: 2_500.00,
            transactionDate: ISO8601DateFormatter()
                .date(from: "2025-06-16T10:20:00Z")!,
            comment: "Абонемент на месяц",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    private var cache = TransactionsFileCache()
    private let calendar = Calendar.current

    private var nextId: Int { (transactions.map { $0.id }.max() ?? 0) + 1 }

    private init() {}

    func fetchTransactions(from start: Date, to end: Date) async throws -> [Transaction] {
        transactions.filter { $0.transactionDate >= start && $0.transactionDate <= end }
    }
    func fetch(from: Date, to: Date) async throws -> [Transaction] {
        transactions.filter { (from ... to).contains($0.transactionDate) }
    }
    @discardableResult
    func createTransaction(accountId: Int,
                           categoryId: Int,
                           amount: Decimal,
                           date: Date,
                           comment: String) -> Transaction {
        let now = Date()
        let tx = Transaction(id: nextId,
                             accountId: accountId,
                             categoryId: categoryId,
                             amount: amount,
                             transactionDate: date,
                             comment: comment,
                             createdAt: now,
                             updatedAt: now)
        transactions.append(tx)
        return tx
    }

    func upgradeTransaction(_ upgrade: Transaction) {
        if let idx = transactions.firstIndex(where: { $0.id == upgrade.id }) {
            transactions[idx] = upgrade
        }
    }

    func deleteTransaction(id: Int) {
        transactions.removeAll { $0.id == id }
    }
}
