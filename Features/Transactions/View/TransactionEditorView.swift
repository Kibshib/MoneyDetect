//
//  TransactionEditorView.swift
//  MoneyDetector
//

import SwiftUI

struct TransactionEditorView: View {

    // MARK: – Режим
    enum Mode {
        case create(direction: Direction)
        case edit(transaction: Transaction, direction: Direction)

        var direction: Direction {
            switch self {
            case .create(let d): return d
            case .edit(_, let d): return d
            }
        }
    }

    // MARK: – Внешние параметры
    let mode: Mode
    var onComplete: (() -> Void)? = nil

    // MARK: – Сервисы
    private let txService  = TransactionServise.shared
    private let catService = CotegoriesServise.shared
    private let accService = BankAccountServise.shared

    // MARK: – Локальное состояние
    @State private var cats: [Category] = []
    @State private var selectedCategory: Category?
    @State private var amountText: String = ""
    @State private var date: Date         = Date()
    @State private var time: Date         = Date()
    @State private var comment: String    = ""


    @Environment(\.dismiss) private var dismiss
    @State private var showCategoryPicker = false
    @State private var showAlert          = false
    @State private var alertMessage       = ""
    @FocusState private var amountFocused : Bool

    private var currentDirection: Direction { mode.direction }

    // MARK: – Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Button("Отмена") { close() }
                        .foregroundColor(Color("ForHistory"))
                    Spacer()
                    Button(actionButtonTitle) { save() }
                        .foregroundColor(Color("ForHistory"))
                }
                .padding(.horizontal)
                .padding(.top, 16)


                Text(title)
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                VStack(spacing: 0) {
                    VStack(spacing: 0) {

                        Button {
 
                            showCategoryPicker = true
  
                            Task { await loadCategoriesIfNeeded() }
                        } label: {
                            HStack {
                                Text("Статья")
                                    .foregroundColor(.black)
                                Spacer()
                                Text(categoryTitle)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                        }

                        Divider().padding(.leading, 16)

                        HStack {
                            Text("Сумма")
                            Spacer()
                            TextField("0", text: $amountText) { _ in formatAmount() }
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .onChange(of: amountText) { amountText = filtered($0) }
                                .foregroundColor(.secondary)
                                .frame(width: 100)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)

                        Divider().padding(.leading, 16)


                        HStack {
                            Text("Дата")
                            Spacer()
                            DatePicker("",
                                       selection: $date,
                                       in: ...Date(),
                                       displayedComponents: .date)
                                .labelsHidden()
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color("AccentColorWithOpacity"))
                                )
                                .padding(.trailing, 0)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)

                        Divider().padding(.leading, 16)

 
                        HStack {
                            Text("Время")
                            Spacer()
                            DatePicker("",
                                       selection: $time,
                                       displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("AccentColorWithOpacity"))
                                )
                                .padding(.trailing, 0)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)

                        Divider().padding(.leading, 16)


                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $comment)
                                .frame(height: 44)
                                .padding(.vertical , 0 )
                                .background(Color.clear)
                            if comment.isEmpty {
                                Text("Комментарий")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.vertical, 2)
                        .frame(height: 44)
                        .background(Color("AccentColorWithOpacity"))
                        .clipShape(RoundedCorner(radius: 8))
                        .padding(.horizontal, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .padding(.top, 16)
                .padding(.horizontal, 16)

        
                if case .edit(let tx, _) = mode {
                    Button(role: .destructive) {
                        Task {
                            await txService.deleteTransaction(id: tx.id)
                            onComplete?()
                            close()
                        }
                    } label: {
                        Text(currentDirection == .income ? "Удалить доход" : "Удалить расход")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .foregroundColor(.red)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                            )
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 20)
            }
            .hideKeyboardOnTap()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Ошибка", isPresented: $showAlert) { } message: { Text(alertMessage) }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                categories: cats,
                selected: $selectedCategory
            )
            .presentationDetents([.medium, .large])
        }

        .task { await initData() }
    }

    // MARK: – Init data
    @MainActor
    private func initData() async {
        await loadCategoriesIfNeeded()
        if case .edit(let tx, _) = mode {
            selectedCategory = cats.first { $0.id == tx.categoryId }
            amountText       = tx.amount.currencyString
            date             = tx.transactionDate
            time             = tx.transactionDate
            comment          = tx.comment
        }
    }


    private func loadCategoriesIfNeeded() async {

        let haveCats = await MainActor.run { !self.cats.isEmpty }
        if haveCats { return }

 
        if catService.categories.isEmpty {
            await catService.loadCategories()
        }

        let filtered = catService.categories.filter {
            currentDirection == .income ? $0.isIncome : !$0.isIncome
        }

        await MainActor.run {
            self.cats = filtered
            if self.selectedCategory == nil, let first = filtered.first {
                self.selectedCategory = first
            }
        }
    }

    // MARK: – UI Strings
    private var title: String {
        switch mode {
        case .create(let d):
            return d == .income ? "Новый доход" : "Новый расход"
        case .edit(_, let d):
            return d == .income ? "Редактирование дохода" : "Редактирование расхода"
        }
    }

    private var actionButtonTitle: String {
        switch mode {
        case .create: return "Добавить"
        case .edit:   return "Сохранить"
        }
    }

    private var categoryTitle: String {
        selectedCategory?.name ?? "Выберите категорию"
    }

    // MARK: – Actions
    private func close() { dismiss() }

    private func save() {
        guard let cat = selectedCategory else {
            showError("Выберите категорию.")
            return
        }
        guard let amt = Decimal.from(string: amountText) else {
            showError("Неверная сумма.")
            return
        }

        let composedDate = composeDateAndTime(date: date, time: time)

        switch mode {
        case .create:
            Task {
                let accountId: Int
                if let acc = accService.account {
                    accountId = acc.id
                } else {
                    await accService.loadMainAccount()
                    guard let acc2 = accService.account else {
                        showError("Счёт недоступен.")
                        return
                    }
                    accountId = acc2.id
                }
                await txService.createTransaction(
                    categoryId: cat.id,
                    amount: amt,
                    date: composedDate,
                    comment: comment
                )
                onComplete?()
                close()
            }
        case .edit(let tx, _):
            Task {
                await txService.updateTransaction(
                    tx,
                    categoryId: cat.id,
                    amount: amt,
                    date: composedDate,
                    comment: comment
                )
                onComplete?()
                close()
            }
        }
    }

    // MARK: – Helpers


    private func formatAmount() {
        if let d = Decimal.from(string: amountText) {
            amountText = d.currencyString
        }
    }


    private func filtered(_ str: String) -> String {
        let sep = decimalSeparator
        var result = str.filter { $0.isWholeNumber || String($0) == sep }

        if result.split(separator: Character(sep)).count > 2 {
            result.removeLast()
        }
        return result
    }

    private var decimalSeparator: String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = .current
        return nf.decimalSeparator ?? ","
    }


    private func composeDateAndTime(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: date)
        let t = cal.dateComponents([.hour,.minute], from: time)
        var comps = DateComponents()
        comps.year = d.year; comps.month = d.month; comps.day = d.day
        comps.hour = t.hour; comps.minute = t.minute
        return cal.date(from: comps) ?? date
    }

    private func showError(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }
}


// MARK: – Category Picker Sheet

private struct CategoryPickerSheet: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ProgressView("Загрузка категорий…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(categories) { cat in
                        HStack {
                            Text(cat.emoji)
                            Text(cat.name)
                            Spacer()
                            if selected?.id == cat.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selected = cat
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Категория")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}


// MARK: – Decimal helpers
private extension Decimal {
    static func from(string: String) -> Decimal? {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale      = Locale.current
        return nf.number(from: string)?.decimalValue
    }
    var currencyString: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale      = Locale.current
        return nf.string(for: self) ?? description
    }
}

#if DEBUG
struct TransactionEditorView_Previews: PreviewProvider {
    private static var mockTx: Transaction {
        Transaction(id: 42,
                    accountId: 1,
                    categoryId: 1,
                    amount: 350,
                    transactionDate: Date(),
                    comment: "Пицца",
                    createdAt: Date(),
                    updatedAt: Date())
    }
    static var previews: some View {
        Group {
            TransactionEditorView(mode: .create(direction: .income))
            TransactionEditorView(mode: .edit(transaction: mockTx, direction: .income))
        }
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .previewDisplayName("Transaction Editor")
    }
}
#endif
