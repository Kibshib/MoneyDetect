//
//  BankAccountServise.swift
//  Networking layer for user BankAccount
//

import Foundation
import Combine

@MainActor
final class BankAccountServise: ObservableObject {
    static let shared = BankAccountServise()

    @Published private(set) var account: BankAccount?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cachedAccountId: Int?
    private let client = NetworkClient.shared

    private init() {}

    // MARK: - Load main (берём первый)
    func loadMainAccount() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let dtos: [AccountResponse] = try await client.request(
                Endpoint(path: "/accounts")
            )
            guard let first = dtos.first else {
                // у пользователя вообще нет счёта
                self.account = nil
                self.cachedAccountId = nil
                return
            }
            let acc = mapAccount(from: first)
            account = acc
            cachedAccountId = acc.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh
    func refreshAccount() async {
        guard let id = cachedAccountId ?? account?.id else {
            await loadMainAccount()
            return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let dto: AccountResponse = try await client.request(
                Endpoint(path: "/accounts/\(id)")
            )
            account = mapAccount(from: dto)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setKnownAccountId(_ id: Int) {
        cachedAccountId = id
    }

    // MARK: - Public: UPDATE / CREATE
    // Обновить существующий счёт на сервере (PUT /accounts/{id}).
    //Если id == 0 → создаём новый (POST /accounts) и сохраняем.
    func updateAccount(newAccount: BankAccount) {
        Task {
            if newAccount.id == 0 {
                await createAccount(newAccount)
            } else {
                await putAccount(newAccount)
            }
        }
    }

    // MARK: - Private network ops

    private func createAccount(_ acc: BankAccount) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let body = CreateAccountBody(
            name: acc.name,
            balance: decimalString(acc.balance),
            currency: acc.currency
        )
        do {
            let dto: AccountResponse = try await client.request(
                Endpoint(path: "/accounts", method: .post),
                body: body
            )
            let mapped = mapAccount(from: dto)
            self.account = mapped
            self.cachedAccountId = mapped.id
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func putAccount(_ acc: BankAccount) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let body = UpdateAccountBody(
            name: acc.name,
            balance: decimalString(acc.balance),
            currency: acc.currency
        )
        do {
            let dto: AccountResponse = try await client.request(
                Endpoint(path: "/accounts/\(acc.id)", method: .put),
                body: body
            )
            let mapped = mapAccount(from: dto)
            self.account = mapped
            self.cachedAccountId = mapped.id
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - API decode DTO

private struct AccountResponse: Decodable {
    let id: Int
    let userId: Int?
    let name: String
    let balance: String
    let currency: String
    let createdAt: String?
    let updatedAt: String?
}

private struct CreateAccountBody: Encodable {
    let name: String
    let balance: String
    let currency: String
}

private struct UpdateAccountBody: Encodable {
    let name: String
    let balance: String
    let currency: String
}

// MARK: - Mapping

private extension BankAccountServise {
    func mapAccount(from dto: AccountResponse) -> BankAccount {
        BankAccount(
            id: dto.id,
            userId: dto.userId ?? 0,
            name: dto.name,
            balance: decimal(from: dto.balance),
            currency: dto.currency,
            createdAt: dto.createdAt ?? "",
            updatedAt: dto.updatedAt ?? ""
        )
    }
}

// MARK: - Helpers

private func decimal(from string: String) -> Decimal {
    Decimal(string: string.replacingOccurrences(of: ",", with: ".")) ?? 0
}

private func decimalString(_ value: Decimal) -> String {
    let nf = NumberFormatter()
    nf.locale = Locale(identifier: "en_US_POSIX")
    nf.minimumFractionDigits = 2
    nf.maximumFractionDigits = 2
    return nf.string(for: value as NSDecimalNumber) ?? "\(value)"
}
