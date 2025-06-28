//
//  TransactionServise.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import Foundation
final class TransactionsService {
    private var cache = TransactionsFileCache()
    private let calendar = Calendar.current
    private var transactions: [Transaction] = [
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
            amount: 30000.00,
            transactionDate: Date(),
            comment: "Зарплата",
            createdAt: Date(),
            updatedAt: Date()
            ),
        Transaction(
            id: 3,
            accountId: 1,
            categoryId: 3,                     // «Продукты»
            amount: Decimal(string: "1450.00")!,
            transactionDate: Date(),
            comment: "Магазин «Пятёрочка»",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 4,
            accountId: 1,
            categoryId: 4,                     // «Транспорт»
            amount: Decimal(string: "55.00")!,
            transactionDate: Date(),
            comment: "Метро",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 5,
            accountId: 1,
            categoryId: 5,                     // «Кафе»
            amount: Decimal(string: "820.00")!,
            transactionDate: Date(),
            comment: "Starbucks",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 6,
            accountId: 1,
            categoryId: 1,                     // «Зарплата» (доход)
            amount: Decimal(string: "30000.00")!,
            transactionDate: ISO8601DateFormatter()
                .date(from: "2025-06-16T08:00:00Z")!,
            comment: "Бонус за проект",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 7,
            accountId: 1,
            categoryId: 6,                     // «Спортзал»
            amount: Decimal(string: "2500.00")!,
            transactionDate: ISO8601DateFormatter()
                .date(from: "2025-06-16T10:20:00Z")!,
            comment: "Абонемент на месяц",
            createdAt: Date(),
            updatedAt: Date()
        )

    ]
    
    
    func feachTransaction(from start: Date , to end : Date) async throws -> [Transaction] {
        return transactions.filter({$0.transactionDate >= start && $0.transactionDate <= end})
    }
    
    func createTransaction(newTransection : Transaction) {
        guard !transactions.contains(where: {$0.id == newTransection.id}) else { return }
        transactions.append(newTransection)
    }
    func upgradeTransaction(upgrade : Transaction)  {
        guard let index = transactions.firstIndex(where: {$0.id == upgrade.id}) else {return}
        transactions[index] = upgrade
    }
    
        
    func fetch(from: Date, to: Date) async throws -> [Transaction] {
            transactions.filter { tx in
                (from ... to).contains(tx.transactionDate)
            }
    }
    
}
