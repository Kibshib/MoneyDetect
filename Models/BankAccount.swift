//
//  BankAccount.swift
//  MoneyDetector
//
//  Created by User on 10.06.2025.
//

import Foundation
struct BankAccount: Codable,Identifiable {
    let id: Int
    let userId : Int
    let name : String
    let balance : Decimal
    let currency : String
    let createdAt : String
    let updatedAt : String
}
