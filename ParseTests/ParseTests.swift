import Foundation
import XCTest
@testable import MoneyDetector

final class TransactionTests: XCTestCase {
    
    func makeSampleTransaction() -> Transaction {
        Transaction(
            id: 1,
            accountId: 100,
            categoryId: 200,
            amount: 999.99,
            transactionDate: ISO8601DateFormatter().date(from: "2025-06-10T10:00:00Z")!,
            comment: "Тестовая транзакция",
            createdAt: ISO8601DateFormatter().date(from: "2025-06-10T11:00:00Z")!,
            updatedAt: ISO8601DateFormatter().date(from: "2025-06-10T12:00:00Z")!
        )
    }
    
    func testJsonObjectEncodingAndParsing() {
        let object = makeSampleTransaction()
        guard let json = object.jsonObject else {
            XCTFail("Не удалось преобразовать в jsonObject")
            return
        }
        guard let parsed = Transaction.parse(jsonObject: json) else {
            XCTFail("Не удалось преобразовать в Transaction")
            return
        }
        
        XCTAssertEqual(object.id, parsed.id)
        XCTAssertEqual(object.accountId, parsed.accountId)
        XCTAssertEqual(object.categoryId, parsed.categoryId)
        XCTAssertEqual(object.amount, parsed.amount)
        XCTAssertEqual(object.transactionDate, parsed.transactionDate)
        XCTAssertEqual(object.comment, parsed.comment)
        XCTAssertEqual(object.createdAt, parsed.createdAt)
        XCTAssertEqual(object.updatedAt, parsed.updatedAt)
    }
}
