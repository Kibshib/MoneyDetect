




import SwiftUI

struct TransactionsListView: View {
    let direction: Direction

    @StateObject private var vm = TransactionsViewModel()
    @State private var categories: [Int: Category] = [:]

    private let categoryService = CategoriesService()

    var body: some View {

        ZStack {

            VStack(spacing: 10) {
                header
                listView
            }
            .task { await reload() }
            .background(Color(.systemGroupedBackground))


            Button { } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(Color("AccentColor"))
                    )
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: .bottomTrailing)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                NavigationLink {
                    HistoryView(categories: categories)
                } label: {
                    Image("History")
                        .renderingMode(.template)
                        .foregroundColor(Color("ForHistory"))
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            }

            Text(direction == .income ? "Доходы сегодня"
                                      : "Расходы сегодня")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, maxHeight: 44, alignment: .leading)


            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(height: 44)
                .overlay(
                    HStack {
                        Text("Всего")
                        Spacer()
                        Text(vm.total.formattedAmount).bold()
                    }
                    .padding(.horizontal, 16)
                )
                .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var listView: some View {
        List {
            Section(header: Text("Операции")
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
                        )
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await reload() }
        .padding(.horizontal, 16)
    }

    // загрузка данных
    private func reload() async {
        async let _ = await loadCategories()
        await vm.load(direction: direction)
    }

    private func loadCategories() async {
        if categories.isEmpty,
           let cats = try? await categoryService.getAllCategories() {
            categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
        }
    }

    // скругление строк
    private func rowCorners(index: Int) -> UIRectCorner {
        if vm.items.count == 1 { return .allCorners }
        if index == 0 { return [.topLeft, .topRight] }
        if index == vm.items.count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }

}
