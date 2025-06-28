//
//  BankAccountServise.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import Foundation
final class BankAccountsService {
    
    private var account = BankAccount(
        id: 1,
        userId: 100,
        name: "Основной счёт",
        balance: 0,
        currency: "RUB",
        createdAt: "2025-06-01T10:00:00Z",
        updatedAt: "2025-06-10T14:00:00Z"
    )
    func getAccount() async -> BankAccount {
          return account
    }
    func updateAccount(newAccount : BankAccount)  {
        account = newAccount
    }
}
