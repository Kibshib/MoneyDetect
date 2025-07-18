//
//  HistoryView.swift
//  MoneyDetector
//
//  История операций за произвольный период.
//  ДИЗАЙН: исходный (Начало/Конец, Сортировка, Сумма, список, Back, Аналитика).
//  FIX: расходы не отображались из-за использования старого TransactionsViewModel,
//       который не подгружал категории/расходы. Теперь данные берём напрямую
//       из сетевых сервисов TransactionServise + CotegoriesServise.
//

import SwiftUI
import UIKit

struct HistoryView: View {

    /// Частичный словарь категорий, проброшенный из родителя (может быть только доходы или только расходы).
    /// Используем как временный fallback до загрузки полного списка.
    let categories: [Int: Category]

    @Environment(\.dismiss) private var dismiss

    // Сетевые сервисы
    @EnvironmentObject private var txService: TransactionServise
    @EnvironmentObject private var categoriesService: CotegoriesServise

    // Локальное состояние данных
    @State private var transactions: [Transaction] = []
    @State private var allCategoriesMap: [Int: Category] = [:]

    // Диапазон: текущий месяц по умолчанию
    @State private var dateFrom: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year,.month], from: Date())) ?? Date()
    }()
    @State private var dateTo: Date = Date()

    // Сортировка
    enum SortKind: String, CaseIterable { case date = "Дата"; case amount = "Сумма" }
    @State private var sortKind: SortKind = .date

    // Редактирование
    @State private var editingTx: Transaction? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {

                // Top bar
                HStack {
                    Text("Моя история")
                        .font(.largeTitle.bold())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .navigationBarBackButtonHidden(true)

                // Карточка управления периодом / сортировкой / суммой
                VStack(spacing: 12) {
                    row(title: "Начало", picker: $dateFrom)
                    row(title: "Конец",  picker: $dateTo)

                    HStack {
                        Text("Сортировка")
                        Spacer()
                        Picker("", selection: $sortKind) {
                            ForEach(SortKind.allCases, id: \.self) { kind in
                                Text(kind.rawValue).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    HStack {
                        Text("Сумма")
                        Spacer()
                        Text(totalSignedFormatted).bold()
                            .padding(.leading , 4)
                    }
                    .padding(.top , 7 )
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .padding(.horizontal, 16)

                listView
            }
            .background(Color(.systemGroupedBackground))

            // первичная загрузка
            .onAppear  { Task { await initialLoad() } }

            // смена начала
            .onChange(of: dateFrom) { newVal in
                if newVal > dateTo { dateTo = newVal }
                Task { await reloadRange() }
            }
            // смена конца
            .onChange(of: dateTo) { newVal in
                if newVal < dateFrom { dateFrom = newVal }
                Task { await reloadRange() }
            }
            // смена сортировки — только локально
            .onChange(of: sortKind) { _ in }

            // редактор
            .sheet(item: $editingTx) { tx in
                TransactionEditorView(
                    mode: .edit(transaction: tx, direction: direction(for: tx))
                ) {
                    Task { await reloadRange() } // после сохранения перезагружаем
                }
            }

            // тулбар
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                    .foregroundColor(Color("ForHistory"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let vc = AnalysisViewController()
                        UIApplication.shared.windows.first?.rootViewController?.present(vc, animated: true)
                    } label: {
                        Image(systemName: "doc")
                            .renderingMode(.template)
                            .foregroundColor(Color("ForHistory"))
                    }
                }
            }
        }
        // индикатор / алерт (через сервисы)
        .overlayLoading(txService.isLoading || categoriesService.isLoading)
        .errorAlert(message: errorBinding)
    }

    // MARK: - Строка с DatePicker
    private func row(title: String, picker: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("", selection: picker, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
    }

    // MARK: - Список
    private var listView: some View {
        List {
            Section(header: Text("Операции")
                        .font(.caption)
                        .textCase(.uppercase)) {
                ForEach(Array(sortedItems.enumerated()), id: \.element.id) { idx, tx in
                    TransactionRow(tx: tx, category: resolvedCategory(for: tx))
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            Rectangle()
                                .fill(Color.white)
                                .clipShape(
                                    RoundedCorner(corners: rowCorners(idx: idx))
                                )
                        )
                        .onTapGesture { editingTx = tx }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }

    // MARK: - Загрузка

    /// Первичная загрузка: категории + период.
    private func initialLoad() async {
        await loadCategoriesIfNeeded()
        await reloadRange()
    }

    /// Грузим все категории (доходы + расходы) с бэкенда.
    private func loadCategoriesIfNeeded(force: Bool = false) async {
        if force || categoriesService.categories.isEmpty {
            await categoriesService.loadCategories(force: force)
        }
        // строим карту на основе сервиса
        allCategoriesMap = Dictionary(uniqueKeysWithValues: categoriesService.categories.map { ($0.id, $0) })
        // fallback на входной словарь, если сервис пуст (неудачный запрос)
        if allCategoriesMap.isEmpty {
            allCategoriesMap = categories
        }
    }

    /// Грузим транзакции за выбранный период.
    private func reloadRange() async {
        // подстрахуемся: категории могли обновиться
        await loadCategoriesIfNeeded()

        // Backend: endDate включительно -> добавляем 1 день и отправляем exclusive
        let endExclusive = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: dateTo)
        )!

        // Сервисная функция — поправь, если у тебя другие аргументы!
        await txService.loadTransactions(startDate: dateFrom, endDate: endExclusive)

        // Копируем в локальный стейт
        transactions = txService.transactions
    }

    // MARK: - Сортировка
    private var sortedItems: [Transaction] {
        switch sortKind {
        case .date:
            return transactions.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            return transactions.sorted { $0.amount > $1.amount }
        }
    }

    // MARK: - Категория для строки (заглушка, если нет)
    private func resolvedCategory(for tx: Transaction) -> Category? {
        if let cat = allCategoriesMap[tx.categoryId] {
            return cat
        }
        // Создаём временный placeholder — чтобы строка не пропала.
        return Category(
            id: tx.categoryId,
            name: "Категория #\(tx.categoryId)",
            emoji: "❓",
            isIncome: false
        )
    }

    // MARK: – Сумма (учитываем знак категории)
    private var totalSigned: Decimal {
        transactions.reduce(0) { partial, tx in
            let isIncome = allCategoriesMap[tx.categoryId]?.isIncome == true
            return partial + (isIncome ? tx.amount : -tx.amount)
        }
    }
    private var totalSignedFormatted: String {
        totalSigned.formattedAmount
    }

    // MARK: – Помощники
    private func rowCorners(idx: Int) -> UIRectCorner {
        let count = sortedItems.count
        if count == 1 { return .allCorners }
        if idx == 0 { return [.topLeft, .topRight] }
        if idx == count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }

    private func direction(for tx: Transaction) -> Direction {
        (allCategoriesMap[tx.categoryId]?.isIncome ?? false) ? .income : .outcome
    }

    // MARK: - Error binding (TxService + Categories)
    private var errorBinding: Binding<String?> {
        Binding<String?>(
            get: { txService.errorMessage ?? categoriesService.errorMessage },
            set: { _ in
                txService.errorMessage = nil
                categoriesService.errorMessage = nil
            }
        )
    }
}
