//
//  Transaction.swift
//  MoneyDetector
//
//  Created by User on 10.06.2025.
//

import Foundation
struct Transaction : Codable,Identifiable {
    let id : Int
    let accountId : Int
    let categoryId : Int
    let amount : Decimal
    let transactionDate : Date
    let comment : String
    let createdAt : Date
    let updatedAt : Date
}
extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject)  else   {return nil}
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Transaction.self, from: data)
    }
    
    var jsonObject: Any? {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(self) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    
    init?(crvLine : String) {
        let components = crvLine.components(separatedBy: ",")
        guard components.count >= 8 else {return nil}
        
        let formate = ISO8601DateFormatter()
        
        guard
            let id = Int(components[0]),
            let accountId = Int(components[1]),
            let categoryId = Int(components[2]),
            let amount = Decimal(string: components[3]),
            let transactionDate = formate.date(from: components[4]),
            let createdAt = formate.date(from: components[6]),
            let updatedAt = formate.date(from: components[7])
        else { return nil }
        
        let comment = components[5]
        
        self.init(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    var csvRepresentation: String {
            let formate = ISO8601DateFormatter()
            let amountStr = "\(amount)"
            
            return [
                "\(id)",
                "\(accountId)",
                "\(categoryId)",
                amountStr,
                formate.string(from: transactionDate),
                comment,
                formate.string(from: createdAt),
                formate.string(from: updatedAt)
            ].joined(separator: ",")
        }
}
