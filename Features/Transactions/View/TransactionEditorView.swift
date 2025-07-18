//
//  TransactionEditorView.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import SwiftUI


struct TransactionEditorView: View {

    // MARK: – Режим
    enum Mode {
        case create(direction: Direction)
        case edit(transaction: Transaction, direction: Direction)
    }

    // MARK: – Внешние зависимости
    let mode: Mode
    var onFinish: (() -> Void)?          // вызывается при успешном save/delete


    private let txService  = TransactionsService.shared
    private let catService = CategoriesService.shared
    private let accService = BankAccountsService.shared


    @State private var selectedCategory: Category?
    @State private var amountText: String = ""
    @State private var date: Date         = Date()
    @State private var time: Date         = Date()
    @State private var comment: String    = ""

    // MARK: – UI-state
    @Environment(\.dismiss) private var dismiss
    @State private var showCategoryPicker = false
    @State private var showAlert          = false
    @State private var alertMessage       = ""
    @FocusState private var amountFocused : Bool

    @State private var categories: [Category] = []
    private let sep = Locale.current.decimalSeparator ?? ","

    var body: some View {
        VStack(spacing: 0) {
           
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
                    .confirmationDialog("Выберите статью",
                                        isPresented: $showCategoryPicker) {
                        ForEach(categories) { cat in
                            Button(cat.name) { selectedCategory = cat }
                        }
                    }
                    .tint(Color("ForHistory"))

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
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color("AccentColorWithOpacity"))
                               
                   
                        )
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                        .labelsHidden()
                        
                        

                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)

                    Divider().padding(.leading, 16)

                    // Время
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
                            .padding(.horizontal, 12)
                            .padding(.vertical , 0 )
                            .background(Color.clear)
                        if comment.isEmpty {
                            Text("Комментарий")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 16)
                
            }
            
        
            if case .edit(let tx, _) = mode {
                Button(role: .destructive) {
                    txService.deleteTransaction(id: tx.id)
                    close()
                } label: {
                    Text(currentDirection == .income ? "Удалить доход" : "Удалить расход")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .padding(.top, 16)        
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Ошибка", isPresented: $showAlert) { }
        message: { Text(alertMessage) }
        .task { await initData() }
    }


    private func initData() async {
        categories = (try? await catService.getExpenseIncome(direction: currentDirection)) ?? []

        guard case .edit(let tx, _) = mode else { return }
        selectedCategory = categories.first { $0.id == tx.categoryId }
        amountText       = tx.amount.currencyString
        date             = tx.transactionDate
        time             = tx.transactionDate
        comment          = tx.comment
    }


    private func save() {
        guard let cat = selectedCategory else { showError("Выберите статью"); return }
        guard let amt = Decimal.from(string: amountText) else { showError("Введите сумму"); return }
        guard !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Введите комментарий"); return
        }


        let composedDate = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute:        Calendar.current.component(.minute, from: time),
            second: 0,
            of: date
        ) ?? date

        switch mode {
        case .create:
            Task {
                if let acc = try? await accService.getMainAccount() {
                    _ = txService.createTransaction(accountId: acc.id,
                                                     categoryId: cat.id,
                                                     amount: amt,
                                                     date: composedDate,
                                                     comment: comment)
                    close()
                }
            }
        case .edit(let tx, _):
            let upd = Transaction(id: tx.id,
                                  accountId: tx.accountId,
                                  categoryId: cat.id,
                                  amount: amt,
                                  transactionDate: composedDate,
                                  comment: comment,
                                  createdAt: tx.createdAt,
                                  updatedAt: Date())
            txService.upgradeTransaction(upd)
            close()
        }
    }

 
    private func filtered(_ str: String) -> String {
        var f = str.filter { $0.isWholeNumber || String($0) == sep }
        if f.split(separator: Character(sep)).count > 2 { f.removeLast() }
        return f
    }

    private func formatAmount() {
        guard !amountText.isEmpty,
              let dec = Decimal.from(string: amountText) else { return }
        amountText = dec.currencyString
    }

    private func showError(_ msg: String) { alertMessage = msg; showAlert = true }
    private func close() { onFinish?(); dismiss() }


    private var currentDirection: Direction {
        switch mode {
        case .create(let d): d
        case .edit(_, let d): d
        }
    }

    private var categoryTitle: String { selectedCategory?.name ?? "—" }

    private var title: String {
        currentDirection == .income ? "Мои Доходы" : "Мои Расходы"
    }

    private var actionButtonTitle: String {
        switch mode { case .create: "Создать"; case .edit: "Сохранить" }
    }
}


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
            TransactionEditorView(mode: .edit(transaction: mockTx,
                                              direction: .income))
        }
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .previewDisplayName("Transaction Editor")
    }
}
#endif
