//
//  BalancePoint.swift
//  MoneyDetector
//
//  Created by mac on 19.07.2025.
//

import Foundation


struct BalancePoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let total: Decimal
}
