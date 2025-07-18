//
//  TransactionsViewModel.swift
//  MoneyDetector
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class TransactionsViewModel: ObservableObject {

    @Published var items: [Transaction] = []
    @Published var total: Decimal       = 0

    private let txService   = TransactionServise.shared
    private let catService  = CotegoriesServise.shared
    private var categories: [Int: Category] = [:]
    private var cancellable: AnyCancellable?
    private var currentDirection: Direction = .income

    init() {
   
        cancellable = txService.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.updateItemsFromService() }
            }
    }


    private func updateItemsFromService() async {
        let all = txService.transactions
        ensureCategoriesLoaded()
        items = all.filter { tx in
            if let cat = categories[tx.categoryId] {
                return currentDirection == .income ? cat.isIncome : !cat.isIncome
            }
            return false
        }
        total = items.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Load «сегодня» под направление
    func load(direction: Direction) async {
        currentDirection = direction
        ensureCategoriesLoaded()
        let (start, end) = todayRange
        await txService.loadTransactions(startDate: start, endDate: end)
        await updateItemsFromService()
    }

    // MARK: - Load интервал c фильтром direction (исп. в History/Date-период)
    func load(from: Date, to: Date, direction: Direction) async {
        currentDirection = direction
        await loadInterval(start: from, end: to, keepFilter: direction)
    }

    // MARK: - Load интервал без смены фильтра (история)
    func load(from: Date, to: Date) async {
        await loadInterval(start: from, end: to, keepFilter: currentDirection)
    }

    // MARK: - Load «всё» (история — без фильтрации по direction)
    func loadAll(from: Date, to: Date) async {
        ensureCategoriesLoaded()
        await txService.loadTransactions(startDate: from, endDate: to)
        items = txService.transactions
        total = items.reduce(0) { $0 + $1.amount }
    }

    // MARK: - CRUD прокси (используются Editor'ом через vm в листе)
    func add(categoryId: Int, amount: Decimal, date: Date, comment: String?) async {
        await txService.createTransaction(categoryId: categoryId, amount: amount, date: date, comment: comment)
        await updateItemsFromService()
    }

    func update(_ tx: Transaction, categoryId: Int, amount: Decimal, date: Date, comment: String?) async {
        await txService.updateTransaction(tx, categoryId: categoryId, amount: amount, date: date, comment: comment)
        await updateItemsFromService()
    }

    func delete(id: Int) async {
        await txService.deleteTransaction(id: id)
        await updateItemsFromService()
    }

    // MARK: - Internal
    private func loadInterval(start: Date, end: Date, keepFilter direction: Direction?) async {
        ensureCategoriesLoaded()
        await txService.loadTransactions(startDate: start, endDate: end)
        let all = txService.transactions

        if let dir = direction {
            items = all.filter { tx in
                if let cat = categories[tx.categoryId] {
                    return dir == .income ? cat.isIncome : !cat.isIncome
                }
                return false
            }
        } else {
            items = all
        }
        total = items.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Categories cache
    private func ensureCategoriesLoaded() {
        if categories.isEmpty {
            categories = Dictionary(uniqueKeysWithValues: catService.categories.map { ($0.id, $0) })
        }
    }

    private var todayRange: (Date, Date) {
        let start = Calendar.current.startOfDay(for: .now)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
