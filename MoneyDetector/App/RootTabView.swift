import SwiftUI

struct RootTabView: View {

    @StateObject private var accountService       = BankAccountServise.shared
    @StateObject private var categoriesService    = CotegoriesServise.shared
    @StateObject private var transactionsService  = TransactionServise.shared // держим живым

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView {
            // Расходы
            NavigationStack {
                TransactionsListView(direction: .outcome)
            }
            .tabItem {
                Image("ic_expenses").renderingMode(.template)
                Text("Расходы")
            }

            // Доходы
            NavigationStack {
                TransactionsListView(direction: .income)
            }
            .tabItem {
                Image("ic_income").renderingMode(.template)
                Text("Доходы")
            }

            // Счёт
            NavigationStack {
                AccountsView()
            }
            .tabItem {
                Image("ic_account").renderingMode(.template)
                Text("Счёт")
            }

            // Статьи
            NavigationStack {
                ArticlesView()
            }
            .tabItem {
                Image("ic_articles").renderingMode(.template)
                Text("Статьи")
            }

            // Настройки (inline текст)
            NavigationStack {
                Text("Настройки в разработке")
                    .foregroundColor(.secondary)
                    .padding()
                    .navigationTitle("Настройки")
            }
            .tabItem {
                Image("ic_settings").renderingMode(.template)
                Text("Настройки")
            }
        }
        .accentColor(Color("AccentColor"))
        // пробрасываем сервисы в окружение
        .environmentObject(accountService)
        .environmentObject(categoriesService)
        .environmentObject(transactionsService)
        // базовые загрузки
        .task {
            await categoriesService.loadCategories()
            await accountService.loadMainAccount()
        }
    }
}
