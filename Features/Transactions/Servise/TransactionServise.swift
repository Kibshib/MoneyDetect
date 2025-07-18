import Foundation
import Combine

@MainActor
final class TransactionServise: ObservableObject {
    static let shared = TransactionServise()

    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = NetworkClient.shared
    private let accountService = BankAccountServise.shared

    private init() {}

    // MARK: Load период
    func loadTransactions(startDate: Date? = nil, endDate: Date? = nil) async {
        if accountService.account == nil {
            await accountService.loadMainAccount()
        }
        guard let accountId = accountService.account?.id else {
            errorMessage = "Счёт недоступен."
            return
        }
        await loadTransactions(accountId: accountId, startDate: startDate, endDate: endDate)
    }

    private func loadTransactions(accountId: Int, startDate: Date?, endDate: Date?) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        var query: [URLQueryItem] = []
        if let s = startDate { query.append(.init(name: "startDate", value: ymdString(s))) }
        if let e = endDate { query.append(.init(name: "endDate", value: ymdString(e))) }

        do {
            let dtos: [TransactionResponse] = try await client.request(
                Endpoint(path: "/transactions/account/\(accountId)/period", query: query)
            )
            transactions = dtos.compactMap(mapTransaction(from:))
            sortTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Create
    func createTransaction(categoryId: Int, amount: Decimal, date: Date, comment: String?) async {
        guard let accountId = accountService.account?.id else {
            errorMessage = "Счёт недоступен."
            return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        let body = CreateTransactionBody(
            accountId: accountId,
            categoryId: categoryId,
            amount: decimalString(amount),
            transactionDate: isoString(date),
            comment: comment?.isEmpty == true ? nil : comment
        )

        do {
            let dto: TransactionResponse = try await client.request(
                Endpoint(path: "/transactions", method: .post),
                body: body
            )
            if let t = mapTransaction(from: dto) {
                transactions.append(t)
                sortTransactions()
            }
            await accountService.refreshAccount() // баланс изменился
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Update
    func updateTransaction(_ transaction: Transaction,
                           categoryId: Int,
                           amount: Decimal,
                           date: Date,
                           comment: String?) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        let body = UpdateTransactionBody(
            accountId: transaction.accountId,
            categoryId: categoryId,
            amount: decimalString(amount),
            transactionDate: isoString(date),
            comment: comment?.isEmpty == true ? nil : comment
        )

        do {
            let dto: TransactionResponse = try await client.request(
                Endpoint(path: "/transactions/\(transaction.id)", method: .put),
                body: body
            )
            if let updated = mapTransaction(from: dto) {
                if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
                    transactions[idx] = updated
                } else {
                    transactions.append(updated)
                }
                sortTransactions()
            }
            await accountService.refreshAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delete
    func deleteTransaction(id: Int) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await client.request(
                Endpoint(path: "/transactions/\(id)", method: .delete),
                body: EmptyPayload(),
                responseType: EmptyPayload.self
            )
            transactions.removeAll { $0.id == id }
            await accountService.refreshAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Helpers

    private func sortTransactions() {
        transactions.sort { $0.transactionDate > $1.transactionDate }
    }
}

// MARK: - Приватные сетевые типы

private struct TransactionResponse: Decodable {
    struct AccountMini: Decodable { let id: Int }
    struct CategoryMini: Decodable { let id: Int }
    let id: Int
    let account: AccountMini
    let category: CategoryMini
    let amount: String
    let transactionDate: String
    let comment: String?
    let createdAt: String?
    let updatedAt: String?
}

private struct CreateTransactionBody: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String?
}

private struct UpdateTransactionBody: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String?
}

// MARK: - Mapping & value helpers

private extension TransactionServise {
    func mapTransaction(from dto: TransactionResponse) -> Transaction? {
        guard let amount = Decimal(string: dto.amount.replacingOccurrences(of: ",", with: ".")) else { return nil }
        guard let txDate = isoDate(dto.transactionDate) else { return nil }
        let created = isoDate(dto.createdAt) ?? txDate
        let updated = isoDate(dto.updatedAt) ?? created

        return Transaction(
            id: dto.id,
            accountId: dto.account.id,
            categoryId: dto.category.id,
            amount: amount,
            transactionDate: txDate,
            comment: dto.comment ?? "",
            createdAt: created,
            updatedAt: updated
        )
    }
}

// MARK: shared helpers

private func decimalString(_ value: Decimal) -> String {
    let nf = NumberFormatter()
    nf.locale = Locale(identifier: "en_US_POSIX")
    nf.minimumFractionDigits = 2
    nf.maximumFractionDigits = 2
    return nf.string(for: value as NSDecimalNumber) ?? "\(value)"
}

private func isoString(_ date: Date) -> String {
    ISO8601DateFormatter.apiMs.string(from: date)
}

private func isoDate(_ string: String?) -> Date? {
    guard let s = string else { return nil }
    return ISO8601DateFormatter.apiMs.date(from: s)
        ?? ISO8601DateFormatter().date(from: s)
}

private func ymdString(_ date: Date) -> String {
    let df = DateFormatter()
    df.calendar = Calendar(identifier: .iso8601)
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "yyyy-MM-dd"
    return df.string(from: date)
}

private extension ISO8601DateFormatter {
    static let apiMs: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
