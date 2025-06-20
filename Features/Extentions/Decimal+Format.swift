



import Foundation

extension Decimal {
    var formattedAmount: String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        nf.groupingSeparator = " "
        return (nf.string(from: self as NSNumber) ?? "0") + " ₽"
    }
}
