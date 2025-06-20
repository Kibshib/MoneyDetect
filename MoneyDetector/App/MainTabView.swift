import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TransactionsListView(direction: .outcome)       // ← вместо ExpensesPlaceholder
                .tabItem {
                    Image("ic_expenses").renderingMode(.template)
                    Text("Расходы")
                }

            TransactionsListView(direction: .income)        // ← вместо IncomePlaceholder
                .tabItem {
                    Image("ic_income").renderingMode(.template)
                    Text("Доходы")
                }

            AccountPlaceholder()
                .tabItem { Image("ic_account").renderingMode(.template); Text("Счёт") }

            ArticlesPlaceholder()
                .tabItem { Image("ic_articles").renderingMode(.template); Text("Статьи") }

            SettingsPlaceholder()
                .tabItem { Image("ic_settings").renderingMode(.template); Text("Настройки") }
        }
        .accentColor(Color("AccentColor"))
    }
}
