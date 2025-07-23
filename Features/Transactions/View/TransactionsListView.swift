import SwiftUI

struct TransactionsListView: View {
    let direction: Direction

    @StateObject private var vm = TransactionsViewModel()
    @State private var categories: [Int: Category] = [:]
    @State private var didAppear = false

    @State private var showCreator = false
    @State private var editingTx: Transaction?

    private let categoryService = CotegoriesServise.shared
    @EnvironmentObject private var accountService: BankAccountServise   // для валюты

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                listView
            }
            .background(Color(.systemGroupedBackground))

            // FAB "+"
            Button {
                showCreator = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color("AccentColor")))
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .bottomTrailing)
        }

        // Создание
        .sheet(isPresented: $showCreator) {
            TransactionEditorView(mode: .create(direction: direction)) {
                Task { await reload() }
            }
        }
        // Редактирование
        .sheet(item: $editingTx) { tx in
            TransactionEditorView(mode: .edit(transaction: tx,
                                              direction: direction)) {
                Task { await reload() }
            }
        }
        // Индикатор / Алерт
        .overlayLoading(categoryService.isLoading || txService.isLoading)
        .errorAlert(message: Binding(
            get: { txService.errorMessage ?? categoryService.errorMessage },
            set: { _ in
                txService.errorMessage = nil
                categoryService.errorMessage = nil
            }
        ))
        .navigationBarHidden(true)
        .onAppear {
            if !didAppear {
                didAppear = true
                Task { await reload() }
            }
        }
    }

    // MARK: – Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Spacer()
                NavigationLink {
                    HistoryView(categories: categories)
                } label: {
                    Image("History")
                        .renderingMode(.template)
                        .foregroundColor(Color("ForHistory"))
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity,
                       alignment: .trailing)
                .padding(.trailing, 16)
            }

            Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity,
                       maxHeight: 44,
                       alignment: .leading)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(height: 44)
                .overlay(
                    HStack {
                        Text("Итого").foregroundColor(.black)
                        Spacer()
                        Text(vm.total.formattedAmount)
                            .bold()
                    }
                    .padding(.horizontal, 16)
                )
                .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: – List
    private var listView: some View {
        List {
            Section(header:
                        Text("Операции")
                        .font(.caption)
                        .textCase(.uppercase)) {

                ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, tx in
                    TransactionRow(tx: tx,
                                   category: categories[tx.categoryId])
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            Rectangle()
                                .fill(Color.white)
                                .clipShape(
                                    RoundedCorner(corners: rowCorners(index: idx))
                                )
                                .padding(.horizontal , 16 )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { editingTx = tx }
                }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: – Reload
    private func reload() async {
        await loadCategories()        
        await vm.load(direction: direction)
    }

    private func loadCategories() async {
        if categories.isEmpty {
            await categoryService.loadCategories()
            categories = Dictionary(uniqueKeysWithValues: categoryService.categories.map { ($0.id, $0) })
        }
    }

    // MARK: – Row corners
    private func rowCorners(index: Int) -> UIRectCorner {
        if vm.items.count == 1 { return .allCorners }
        if index == 0 { return [.topLeft, .topRight] }
        if index == vm.items.count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }

    // MARK: – Shortcut to txService (для overlay / alert)
    private var txService: TransactionServise { .shared }
}
