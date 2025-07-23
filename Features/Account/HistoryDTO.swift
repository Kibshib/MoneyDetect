//
//  HistoryDTO.swift
//  MoneyDetector
//

import Foundation


struct AccountHistoryResponseDTO: Decodable {
    let accountId        : Int
    let accountName      : String
    let currency         : String
    let currentBalance   : String      
    let history          : [BalanceHistoryDTO]
}


struct BalanceHistoryDTO: Decodable, Identifiable {
    struct State: Decodable {
        let balance : String
    }

    let id               : Int
    let changeType       : String
    let previousState    : State?
    let newState         : State
    let changeTimestamp  : String




    var changeTimestampDate: Date {
        makeISO8601ApiFormatter().date(from: changeTimestamp) ?? .distantPast
    }


    var balanceDecimal: Decimal {
        Decimal(string: newState.balance.replacingOccurrences(of: ",", with: ".")) ?? .zero
    }
}

private func makeISO8601ApiFormatter() -> ISO8601DateFormatter {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f.timeZone = .init(secondsFromGMT: 0)
    return f
}
