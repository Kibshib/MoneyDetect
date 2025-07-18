//
//  HistoryView.swift
//  MoneyDetector
//


import SwiftUI
import UIKit

struct HistoryView: View {


    let categories: [Int: Category]

    @Environment(\.dismiss) private var dismiss


    @EnvironmentObject private var txService: TransactionServise
    @EnvironmentObject private var categoriesService: CotegoriesServise


    @State private var transactions: [Transaction] = []
    @State private var allCategoriesMap: [Int: Category] = [:]


    @State private var dateFrom: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year,.month], from: Date())) ?? Date()
    }()
    @State private var dateTo: Date = Date()


    enum SortKind: String, CaseIterable { case date = "Дата"; case amount = "Сумма" }
    @State private var sortKind: SortKind = .date

    @State private var editingTx: Transaction? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {

          
                HStack {
                    Text("Моя история")
                        .font(.largeTitle.bold())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .navigationBarBackButtonHidden(true)


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


            .onAppear  { Task { await initialLoad() } }


            .onChange(of: dateFrom) { newVal in
                if newVal > dateTo { dateTo = newVal }
                Task { await reloadRange() }
            }

            .onChange(of: dateTo) { newVal in
                if newVal < dateFrom { dateFrom = newVal }
                Task { await reloadRange() }
            }

            .onChange(of: sortKind) { _ in }


            .sheet(item: $editingTx) { tx in
                TransactionEditorView(
                    mode: .edit(transaction: tx, direction: direction(for: tx))
                ) {
                    Task { await reloadRange() }
                }
            }

  
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

        .overlayLoading(txService.isLoading || categoriesService.isLoading)
        .errorAlert(message: errorBinding)
    }


    private func row(title: String, picker: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("", selection: picker, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
    }


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




    private func initialLoad() async {
        await loadCategoriesIfNeeded()
        await reloadRange()
    }


    private func loadCategoriesIfNeeded(force: Bool = false) async {
        if force || categoriesService.categories.isEmpty {
            await categoriesService.loadCategories(force: force)
        }
 
        allCategoriesMap = Dictionary(uniqueKeysWithValues: categoriesService.categories.map { ($0.id, $0) })
   
        if allCategoriesMap.isEmpty {
            allCategoriesMap = categories
        }
    }


    private func reloadRange() async {

        await loadCategoriesIfNeeded()


        let endExclusive = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: dateTo)
        )!


        await txService.loadTransactions(startDate: dateFrom, endDate: endExclusive)


        transactions = txService.transactions
    }


    private var sortedItems: [Transaction] {
        switch sortKind {
        case .date:
            return transactions.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            return transactions.sorted { $0.amount > $1.amount }
        }
    }


    private func resolvedCategory(for tx: Transaction) -> Category? {
        if let cat = allCategoriesMap[tx.categoryId] {
            return cat
        }
  
        return Category(
            id: tx.categoryId,
            name: "Категория #\(tx.categoryId)",
            emoji: "❓",
            isIncome: false
        )
    }


    private var totalSigned: Decimal {
        transactions.reduce(0) { partial, tx in
            let isIncome = allCategoriesMap[tx.categoryId]?.isIncome == true
            return partial + (isIncome ? tx.amount : -tx.amount)
        }
    }
    private var totalSignedFormatted: String {
        totalSigned.formattedAmount
    }


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
