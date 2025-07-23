//
//  ArticleModel.swift
//  MoneyDetector
//
//  Created by mac on 17.07.2025.
//


import Foundation

struct Article: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
}

extension Article {
    init(category: Category) {
        self.id = category.id
        self.title = category.name
        self.icon = category.emoji
    }
}
