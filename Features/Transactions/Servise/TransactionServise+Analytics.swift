import Foundation
import Combine

/// Расчёт агрегированных балансов для графика.
/// НЕ меняет исходные данные (поле `amount` остаётся как приходит из бэка).
extension TransactionServise {



    func makeDailyBalancePoints(depth: Int, calendar: Calendar = .current) -> [BalancePoint] {
        let today = stripTimeToDayUTC(Date())
        let start = calendar.date(byAdding: .day, value: -depth, to: today)!
        let isIncome: (Int) -> Bool = { id in
            CotegoriesServise.shared.categories.first { $0.id == id }?.isIncome ?? true
        }
        let sortedTx = transactions.sorted { $0.transactionDate < $1.transactionDate }
        print("[DEBUG] Все транзакции:", sortedTx.map { $0.transactionDate })
        var dayBalances: [Date: Decimal] = [:]
        var runningTotal: Decimal = 0
        var txIndex = 0
        // Считаем баланс на конец каждого дня
        for offset in 0...depth {
            let dayDate = calendar.date(byAdding: .day, value: offset, to: start)!
            let dayDateStripped = stripTimeToDayUTC(dayDate)
            print("[DEBUG] dayDate:", dayDateStripped)
            while txIndex < sortedTx.count && stripTimeToDayUTC(sortedTx[txIndex].transactionDate) == dayDateStripped {
                let tx = sortedTx[txIndex]
                let signed = isIncome(tx.categoryId) ? tx.amount : -tx.amount
                runningTotal += signed
                txIndex += 1
            }
            dayBalances[dayDateStripped] = runningTotal
        }
        // Считаем разницу между днями
        var points: [BalancePoint] = []
        for offset in 0..<depth {
            let prevDay = calendar.date(byAdding: .day, value: offset, to: start)!
            let currDay = calendar.date(byAdding: .day, value: offset+1, to: start)!
            let prevDayStripped = stripTimeToDayUTC(prevDay)
            let currDayStripped = stripTimeToDayUTC(currDay)
            let diff = (dayBalances[currDayStripped] ?? 0) - (dayBalances[prevDayStripped] ?? 0)
            points.append(BalancePoint(date: currDayStripped, total: diff))
        }
        print("[DEBUG] Даты точек графика:", points.map { $0.date })
        return points
    }

    // Изменение баланса за каждый из depth последних месяцев (учитывая isIncome категории)
    func makeMonthlyBalancePoints(depth: Int, calendar: Calendar = .current) -> [BalancePoint] {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        let currentMonth = calendar.date(from: comps)!
        let isIncome: (Int) -> Bool = { id in
            CotegoriesServise.shared.categories.first { $0.id == id }?.isIncome ?? true
        }
        let sortedTx = transactions.sorted { $0.transactionDate < $1.transactionDate }
        var monthBalances: [Date: Decimal] = [:]
        var runningTotal: Decimal = 0
        var txIndex = 0
        for offset in (-depth)...0 {
            let monthDate = calendar.date(byAdding: .month, value: offset, to: currentMonth)!
            while txIndex < sortedTx.count && calendar.isDate(sortedTx[txIndex].transactionDate, equalTo: monthDate, toGranularity: .month) {
                let tx = sortedTx[txIndex]
                let signed = isIncome(tx.categoryId) ? tx.amount : -tx.amount
                runningTotal += signed
                txIndex += 1
            }
            monthBalances[monthDate] = runningTotal
        }
        var points: [BalancePoint] = []
        for offset in (-depth+1)...0 {
            let prevMonth = calendar.date(byAdding: .month, value: offset-1, to: currentMonth)!
            let currMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth)!
            let diff = (monthBalances[currMonth] ?? 0) - (monthBalances[prevMonth] ?? 0)
            points.append(BalancePoint(date: currMonth, total: diff))
        }
        return points
    }




    private func aggregate(component: Calendar.Component,
                           depth: Int,
                           calendar: Calendar) -> [BalancePoint] {

        let catService = CotegoriesServise.shared
        let isIncome: (Int) -> Bool = { id in
            catService.categories.first { $0.id == id }?.isIncome ?? true
        }

        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: component, value: -depth + 1, to: today)!

 
        func periodKey(for date: Date) -> Date {
            switch component {
            case .day:
                return calendar.startOfDay(for: date)
            case .month:
                let comps = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: comps) ?? date
            default:
                return date
            }
        }
        let grouped = Dictionary(grouping: transactions.filter { $0.transactionDate >= start }, by: { periodKey(for: $0.transactionDate) })

        var points: [BalancePoint] = []
        for offset in 0..<depth {
            guard let d = calendar.date(byAdding: component, value: -offset, to: today) else { continue }
            let key = periodKey(for: d)
            let sum = grouped[key]?.reduce(Decimal(0)) { acc, tx in
                let signed = isIncome(tx.categoryId) ? tx.amount : -tx.amount
                return acc + signed
            } ?? 0
            points.append(BalancePoint(date: d, total: sum))
        }
        return points.reversed()
    }
}


private func stripTimeToDayUTC(_ date: Date) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let comps = calendar.dateComponents([.year, .month, .day], from: date)
    return calendar.date(from: comps)!
}
