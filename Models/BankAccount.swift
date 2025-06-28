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
    var balance : Decimal
    var currency : String
    let createdAt : String
    let updatedAt : String
}
