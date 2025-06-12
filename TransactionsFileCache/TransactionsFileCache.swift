//
//  TransactionsFileCache.swift
//  MoneyDetector
//
//  Created by User on 10.06.2025.
//

import Foundation
final class TransactionsFileCache {
    private(set) var transactions : [Transaction] = []
    
    func addTransaction(_ transaction : Transaction) {
        guard !transactions.contains(where: {$0.id == transaction.id}) else {return}
        transactions.append(transaction)
    }
    
    func removeTransaction(id id : Int) {
        transactions.removeAll(where: {$0.id == id})
    }
    
    
    func save(fileName : String) {
        let jsonArr : [Any] = transactions.compactMap( {$0.jsonObject} )
        do
        {
            let data = try JSONSerialization.data(withJSONObject: jsonArr)
            let url = try getFileURL(fileName : fileName)
            try data.write(to: url)
        } catch {
            
        }
    }
    
    
    func load(fileName : String ) {
        do
        {
            let url = try getFileURL(fileName: fileName)
            let data = try Data(contentsOf: url)
            guard let jsonArr = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                return
            }
            let loadedTransaction = jsonArr.compactMap({Transaction.parse(jsonObject: $0)})
            for i in loadedTransaction {
                addTransaction(i)
            }
        } catch {
            
        }
        
        
        
    }
    private func getFileURL(fileName: String) throws -> URL {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return directory.appendingPathComponent(fileName)
        }
}
