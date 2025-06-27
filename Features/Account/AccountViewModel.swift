import SwiftUI
import CoreMotion

@MainActor
final class BankAccountViewModel: ObservableObject {
    @Published var account = BankAccount(
        id: 0, userId: 0, name: "", balance: 0,
        currency: "RUB", createdAt: "", updatedAt: ""
    )
    @Published var balanceString = "0"
    @Published var currency: Currency = .rub

    @Published var isRefreshing = false

    @Published var isBalanceHidden = false

    private let service = BankAccountsService()
    private let motionManager = CMMotionManager()

    init() {
        Task { await load() }
        startShakeDetection()
    }

    func load() async {
        let acc = await service.getAccount()
        account = acc
        balanceString = "\(NSDecimalNumber(decimal: acc.balance).intValue)"
        currency = Currency(rawValue: acc.currency) ?? .rub
    }

    func refresh() async {
        isRefreshing = true
        await load()
        isRefreshing = false
    }

    func save() {
        let now = ISO8601DateFormatter().string(from: Date())
        let dec = Decimal(string: balanceString.filter { $0.isNumber }) ?? 0
        let updated = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: dec,
            currency: currency.rawValue,
            createdAt: account.createdAt,
            updatedAt: now
        )
        service.updateAccount(newAccount: updated)
        account = updated
    }

    var formattedBalance: String {
        let num = NSDecimalNumber(decimal: account.balance).intValue
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = " "
        return fmt.string(from: NSNumber(value: num)) ?? "0"
    }

    func pasteBalance(from pasteboard: UIPasteboard) {
        let text = pasteboard.string ?? ""
        let filtered = text.filter { $0.isNumber }
        if !filtered.isEmpty {
            balanceString = filtered
        }
    }

    private func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            if let g = data?.acceleration,
               abs(g.x) > 2 || abs(g.y) > 2 || abs(g.z) > 2 {
                withAnimation(.easeInOut) {
                    self.isBalanceHidden.toggle()
                }
            }
        }
    }
}
