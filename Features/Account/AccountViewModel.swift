//
//  AccountViewModel.swift
//  MoneyDetector
//
import Combine
import SwiftUI
import CoreMotion

@MainActor
final class BankAccountViewModel: ObservableObject {

    @Published var account = BankAccount(
        id: 0, userId: 0, name: "Мой счёт", balance: 0,
        currency: "RUB", createdAt: "", updatedAt: ""
    )
    @Published var balanceString = "0"
    @Published var currency: Currency = .rub

    @Published var isRefreshing = false
    @Published var isSaving = false

    @Published var isBalanceHidden = false

  
    @Published private(set) var isLoadingFromService = false
    @Published var serviceError: String?


    private let service = BankAccountServise.shared
    private var cancellables: [AnyCancellable] = []


    private let motionManager = CMMotionManager()

    init() {
  
        service.$account
            .receive(on: DispatchQueue.main)
            .sink { [weak self] acc in
                guard let self, let acc else { return }
                self.apply(account: acc)
            }
            .store(in: &cancellables)

        service.$isLoading
            .assign(to: &$isLoadingFromService)

        service.$errorMessage
            .assign(to: &$serviceError)

        startShakeDetection()
    }



    func load() async {
        if service.account == nil {
            await service.loadMainAccount()
        } else {
            await service.refreshAccount()
        }

    }

    func refresh() async {
        isRefreshing = true
        await service.refreshAccount()
        isRefreshing = false
    }


    func save() {
        guard !isSaving else { return }
        isSaving = true
        let now = ISO8601DateFormatter().string(from: Date())


        let dec = Decimal(string: balanceString.replacingOccurrences(of: ",", with: ".").filter { $0.isNumber || $0 == "." }) ?? 0

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


        apply(account: updated)

        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run { self.isSaving = false }
        }
    }


    private func apply(account acc: BankAccount) {
        self.account = acc
        self.balanceString = balanceToString(acc.balance)
        self.currency = Currency(rawValue: acc.currency) ?? .rub
    }



    var formattedBalance: String {
        numberGroupString(from: account.balance)
    }

    private func balanceToString(_ value: Decimal) -> String {
        numberGroupString(from: value, noSeparatorsOk: true)
    }


    private func numberGroupString(from value: Decimal, noSeparatorsOk: Bool = false) -> String {
        let num = NSDecimalNumber(decimal: value)
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = " "
        fmt.decimalSeparator = ","
        fmt.maximumFractionDigits = 2
        fmt.minimumFractionDigits = 0
        let s = fmt.string(from: num) ?? (noSeparatorsOk ? "\(num)" : "0")
        return s
    }


    private func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let g = data?.acceleration else { return }
            if abs(g.x) > 2 || abs(g.y) > 2 || abs(g.z) > 2 {
                withAnimation(.easeInOut) {
                    self.isBalanceHidden.toggle()
                }
            }
        }
    }
}
