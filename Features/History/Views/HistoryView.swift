

import SwiftUI

struct HistoryView: View {
    let categories: [Int: Category]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TransactionsViewModel()

    // диапазон по умолчанию
    @State private var dateFrom = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
    @State private var dateTo   = Date()

    // выбор сортировки
    enum SortKind: String, CaseIterable { case date = "Дата"; case amount = "Сумма" }
    @State private var sortKind: SortKind = .date

    var body: some View {
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
                    Button { /* share */ } label: {
                        Image(systemName: "doc")
                            .renderingMode(.template)
                            .foregroundColor(Color("ForHistory"))
                    }
                }
            }

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
                    Text(vm.total.formattedAmount).bold()
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
        .onAppear  { Task { await reload() } }
        .onChange(of: dateFrom) { newVal in
            if newVal > dateTo { dateTo = newVal }
            Task { await reload() }
        }
        .onChange(of: dateTo) { newVal in
            if newVal < dateFrom { dateFrom = newVal }
            Task { await reload() }
        }
        .onChange(of: sortKind) { _ in }
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
                    TransactionRow(tx: tx, category: categories[tx.categoryId])
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            Rectangle()
                                .fill(Color.white)
                                .clipShape(
                                    RoundedCorner(corners: rowCorners(idx: idx))
                                )
                        )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }


    private func reload() async {
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1,
                      to: Calendar.current.startOfDay(for: dateTo))!
        await vm.load(from: dateFrom, to: endOfDay)
    }

    private var sortedItems: [Transaction] {
        switch sortKind {
        case .date:   return vm.items.sorted { $0.transactionDate > $1.transactionDate }
        case .amount: return vm.items.sorted { $0.amount > $1.amount }
        }
    }

    private func rowCorners(idx: Int) -> UIRectCorner {
        if vm.items.count == 1 { return .allCorners }
        if idx == 0 { return [.topLeft, .topRight] }
        if idx == vm.items.count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }
}
