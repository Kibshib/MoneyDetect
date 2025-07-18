//
//  AccountViewModel.swift
//  MoneyDetector
//
import Combine
import SwiftUI
import CoreMotion

@MainActor
final class BankAccountViewModel: ObservableObject {
    // Публичные данные для UI
    @Published var account = BankAccount(
        id: 0, userId: 0, name: "Мой счёт", balance: 0,
        currency: "RUB", createdAt: "", updatedAt: ""
    )
    @Published var balanceString = "0"
    @Published var currency: Currency = .rub

    @Published var isRefreshing = false
    @Published var isSaving = false

    @Published var isBalanceHidden = false

    // Ошибки/загрузка берём из сервиса (подпишемся)
    @Published private(set) var isLoadingFromService = false
    @Published var serviceError: String?

    // сервис
    private let service = BankAccountServise.shared
    private var cancellables: [AnyCancellable] = []

    // Shake
    private let motionManager = CMMotionManager()

    init() {
        // Подписки: когда сервис обновляет счёт → синк в локальную модель
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

    // MARK: - Load / Refresh

    func load() async {
        if service.account == nil {
            await service.loadMainAccount()
        } else {
            await service.refreshAccount()
        }
        // локальные поля обновятся через sink
    }

    func refresh() async {
        isRefreshing = true
        await service.refreshAccount()
        isRefreshing = false
    }

    // MARK: - Save (PUT /accounts)
    func save() {
        guard !isSaving else { return }
        isSaving = true
        let now = ISO8601DateFormatter().string(from: Date())

        // Парсим Decimal из строки (только цифры)
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

        // Локально сразу обновим, чтобы UI отрисовался; сервис позже подтянет с сервера
        apply(account: updated)

        // Сбрасываем saving через небольшую задержку (когда сервис успеет ответить)
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run { self.isSaving = false }
        }
    }

    // MARK: - Apply account → локальные поля
    private func apply(account acc: BankAccount) {
        self.account = acc
        self.balanceString = balanceToString(acc.balance)
        self.currency = Currency(rawValue: acc.currency) ?? .rub
    }

    // MARK: helpers

    var formattedBalance: String {
        numberGroupString(from: account.balance)
    }

    private func balanceToString(_ value: Decimal) -> String {
        numberGroupString(from: value, noSeparatorsOk: true)
    }

    /// Разбивка по тысячам пробелами
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

    // MARK: Shake hide
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
