import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let category: Category?


    init(tx: Transaction, category: Category?) {
        self.transaction = tx
        self.category = category
    }

    init(transaction: Transaction, category: Category?) {
        self.transaction = transaction
        self.category = category
    }

    private var circleColor: Color {
        Color("AccentColor").opacity(0.15)
    }

    var body: some View {
        HStack(spacing: 12) {


            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 32, height: 32)
                Text(category?.emoji ?? defaultEmoji)
                    .font(.system(size: 16))
            }
            .padding(.leading, 16)


            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Категория?")
                    .font(.system(size: 17))
                Text(detailText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()


            Text(formattedAmount)
                .font(.system(size: 17))
    

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
        }.padding(.horizontal , 16 )
        .frame(height: 36)
    }

    private var defaultEmoji: String {
        category?.isIncome == true ? "⬆️" : "⬇️"
    }

    private var detailText: String {
    
        let comment = transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !comment.isEmpty { return comment }
        let df = DateFormatter()
        df.dateStyle = .short
        return df.string(from: transaction.transactionDate)
    }

    private var formattedAmount: String {

        if let ext = transaction.amount.formattedAmountIfAvailable {
            return ext
        }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        let s = nf.string(for: transaction.amount as NSDecimalNumber) ?? "\(transaction.amount)"
        let sign = category?.isIncome == true ? "+" : "-"
        return sign + s
    }
}

private extension Decimal {
    var formattedAmountIfAvailable: String? {

        nil
    }
}
