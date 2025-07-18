//
//  ArticlesViewModel.swift
//  MoneyDetector
//

import Combine
import SwiftUI

@MainActor
final class ArticlesViewModel: ObservableObject {

    // Полный список статей (из категорий)
    @Published private(set) var articles: [Article] = []

    // Текст поиска
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }

    // Отфильтрованный список
    @Published private(set) var filtered: [Article] = []

    // Сервис категорий (сеть + кэш)
    private let catService = CotegoriesServise.shared

    init() {
        // Когда сервис обновил категории — перестраиваем статьи
        catService.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildArticles()
            }
            .store(in: &cancellables)
    }

    // MARK: API

    /// Первичная (или форс) загрузка категорий
    func reload(force: Bool = false) async {
        await catService.loadCategories(force: force)
        rebuildArticles()
    }

    /// Пересобрать массив `articles` из сервиса
    func rebuildArticles() {
        articles = catService.categories.map(Article.init(category:))
        applyFilter()
    }

    // MARK: Filtering

    private func applyFilter() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            filtered = articles
            return
        }
        filtered = articles.filter {
            Self.fuzzy(src: $0.title, pat: q) ||
            Self.fuzzy(src: $0.icon,  pat: q)
        }
    }

    // MARK: – Fuzzy (минимальный)
    private static func fuzzy(src: String, pat: String) -> Bool {
        let s = src.lowercased(), p = pat.lowercased()
        var i = s.startIndex
        for ch in p {
            guard let found = s[i...].firstIndex(of: ch) else { return false }
            i = s.index(after: found)
        }
        return true
    }

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()
}
