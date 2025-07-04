//
//  ArticlesViewModel.swift
//  MoneyDetector
//

import Combine
import SwiftUI

@MainActor
final class ArticlesViewModel: ObservableObject {

    @Published private(set) var articles: [Article] = []
    @Published var searchText: String = ""
    @Published private(set) var filtered: [Article] = []

    private let catService = CategoriesService()

    init() {
        Publishers.CombineLatest($articles, $searchText)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)      // плавнее
            .map { list, query in
                guard !query.isEmpty else { return list }
                return list.filter { Self.fuzzy(src: $0.title, pat: query) }
            }
            .assign(to: &$filtered)

        Task { await loadCategories() }
    }

    func reload() async { await loadCategories() }

    // MARK: – Data

    private func loadCategories() async {
        guard let cats = try? await catService.getAllCategories() else { return }
        articles = cats.map { Article(id: $0.id, title: $0.name, icon: $0.emoji) }
        filtered = articles
    }

    // MARK: – Fuzzy без сторонних библиотек

    private static func fuzzy(src: String, pat: String) -> Bool {
        let s = src.lowercased(), p = pat.lowercased()
        var i = s.startIndex
        for ch in p {
            guard let found = s[i...].firstIndex(of: ch) else { return false }
            i = s.index(after: found)
        }
        return true
    }
}
