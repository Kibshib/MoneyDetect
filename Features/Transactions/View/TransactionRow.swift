


import SwiftUI

struct TransactionRow: View {
    let tx: Transaction
    let category: Category?

    private var circleColor: Color {
        Color("AccentColor").opacity(0.15)
    }

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 32, height: 32)
                    
                Text(category?.emoji ?? "⬜️")
                    .font(.system(size: 16))
                    
            }
            .padding(.leading , 16 )
            

            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Категория")
                    .font(.system(size: 17))
                    .padding(.leading , 5)// 17 pt
                if !tx.comment.isEmpty {
                    Text(tx.comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading , 5)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text(tx.amount.formattedAmount)
                    .font(.system(size: 17))
                    .padding(.trailing , 10)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
        }
        .frame(height: 36)

    }
}
