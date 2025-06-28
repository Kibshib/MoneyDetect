// 4 дз
//  ArticlesViewModel.swift
//  MoneyDetector
//
//  Created by mac on 28.06.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published var searchText: String = ""
    @Published private(set) var filtered: [Article] = []

    private let catService = CategoriesService()
    private var bag = Set<AnyCancellable>()

    init() {
        // наблюдаем за поиском
        Publishers.CombineLatest($articles, $searchText)
            .map { list, query in
                guard !query.isEmpty else { return list }
                return list.filter { Self.fuzzy(src: $0.title, pat: query) }
            }
            .assign(to: &self.$filtered)

        Task { await loadCategories() }
    }

    func reload() async { await loadCategories() }

    private func loadCategories() async {
        guard let cats = try? await catService.getAllCategories() else { return }
        // маппим в Article
        articles = cats.map { Article(id: $0.id, title: $0.name, icon: $0.emoji) }
        filtered = articles                          // показать сразу
    }

    private static func fuzzy(src: String, pat: String) -> Bool {
        var idx = src.lowercased().startIndex
        for ch in pat.lowercased() {
            guard let f = src.lowercased()[idx...].firstIndex(of: ch) else { return false }
            idx = src.lowercased().index(after: f)
        }
        return true
    }
}
