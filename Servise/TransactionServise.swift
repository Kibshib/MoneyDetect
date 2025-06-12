//
//  TransactionServise.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import Foundation
final class TransactionsService {
    
    private var transactions: [Transaction] = [
        Transaction(
            id: 1,
            accountId: 1,
            categoryId: 2,
            amount: 350.00,
            transactionDate: ISO8601DateFormatter().date(from: "2025-06-08T12:00:00Z")!,
            comment: "Пицца",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 2,
            accountId: 1,
            categoryId: 1,
            amount: 30000.00,
            transactionDate: ISO8601DateFormatter().date(from: "2025-06-05T09:00:00Z")!,
            comment: "Зарплата",
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
    
}
