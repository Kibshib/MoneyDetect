//import SwiftUI
//
//struct CurrencySheet: View {
//    let current: Currency
//    let onSelect: (Currency) -> Void
//
//    var body: some View {
//        VStack(spacing: 0) {
//            Text("Валюта")
//                .font(.footnote.weight(.semibold))
//                .padding(.vertical, 12)
//
//            ForEach(Currency.allCases) { cur in
//                Button {
//                    onSelect(cur)
//                } label: {
//                    HStack {
//                        Text(cur.fullName)
//                            .foregroundColor(.primary)
//                        Spacer()
//                        if cur == current {
//                            Image(systemName: "checkmark")
//                                .foregroundColor(.accentColor)
//                        }
//                    }
//                    .frame(height: 44)
//                }
//                .disabled(cur == current)
//
//                if cur != Currency.allCases.last { Divider() }
//            }
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(.systemBackground))
//        )
//        .padding(24)
//    }
//}
