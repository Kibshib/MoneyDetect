import Foundation
import SwiftUI

@MainActor
final class TransactionsViewModel: ObservableObject {

    @Published var items: [Transaction] = []
    @Published var total: Decimal       = 0

    private let txService   = TransactionsService()
    private let catService  = CategoriesService()
    private var categories: [Int: Category] = [:]

    func load(direction: Direction) async {
        // Если категории не загружены — загрузить
        if categories.isEmpty {
            if let cats = try? await catService.getAllCategories() {
                categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
            }
        }

        //  Операции за сегодняшний день
        let (start, end) = todayRange
        guard let all = try? await txService.fetch(from: start, to: end) else { return }

        // Фильтрация по isIncome категории
        items = all.filter { tx in
            if let cat = categories[tx.categoryId] {
                return direction == .income ? cat.isIncome : !cat.isIncome
            }
            return false
        }
        total = items.reduce(0) { $0 + $1.amount }
    }

    private var todayRange: (Date, Date) {
        let start = Calendar.current.startOfDay(for: .now)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
    
    func load(from: Date, to: Date) async {
        await loadInterval(start: from, end: to, keepFilter: nil)
    }

    private func loadInterval(start: Date, end   : Date, keepFilter direction: Direction?) async {
        
        if categories.isEmpty {
            if let cats = try? await catService.getAllCategories() {
                categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
            }
        }
        guard let all = try? await txService.fetch(from: start, to: end) else { return }

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

}
