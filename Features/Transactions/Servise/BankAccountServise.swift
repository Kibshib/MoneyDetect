//
//  BankAccountServise.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import Foundation
final class BankAccountsService {
    static let shared = BankAccountsService()
    private var mainAccount = BankAccount(
        id: 1,
        userId: 1,
        name: "Основной счёт",
        balance: 0,
        currency: "RUB",
        createdAt: "",
        updatedAt: ""
    )
    private init() {}
    func getAccount() async -> BankAccount {
        return mainAccount
    }
    func updateAccount(newAccount : BankAccount)  {
        mainAccount = newAccount
    }
    func getMainAccount() async throws -> BankAccount {
        mainAccount
    }
}


