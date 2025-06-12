//
//  MoneyDetector.swift
//  MoneyDetector
//
//  Created by User on 10.06.2025.
//

import Foundation
enum Direction : String , Codable {
    case income
    case outcome
}
struct Category: Codable {
    let id : Int
    let name : String
    let emoji : String
    let isIncome : Bool
    var direction : Direction {
        return isIncome ? .income : .outcome
    }
    var emodjiCharacter : Character? {
        return emoji.first
    }
}
