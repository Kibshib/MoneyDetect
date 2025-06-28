//
//  RootTabView.swift
//  MoneyDetector
//
//  Created by User on 20.06.2025.
//
import SwiftUI

struct RootTabView: View {

 
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

            // остальные вкладки
            NavigationStack { AccountsView() }
                .tabItem { Image("ic_account").renderingMode(.template); Text("Счёт") }

            NavigationStack { ArticlesView() }
                .tabItem { Image("ic_articles").renderingMode(.template); Text("Статьи") }

            NavigationStack { SettingsPlaceholder() }
                .tabItem { Image("ic_settings").renderingMode(.template); Text("Настройки") }
        }
        .accentColor(Color("AccentColor"))
       
    }
}

