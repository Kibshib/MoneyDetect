//
//  ArticlesViewModel.swift
//  MoneyDetector
//

import Combine
import SwiftUI

@MainActor
final class ArticlesViewModel: ObservableObject {


    @Published private(set) var articles: [Article] = []


    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }


    @Published private(set) var filtered: [Article] = []

    private let catService = CotegoriesServise.shared

    init() {
   
        catService.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildArticles()
            }
            .store(in: &cancellables)
    }


    func reload(force: Bool = false) async {
        await catService.loadCategories(force: force)
        rebuildArticles()
    }


    func rebuildArticles() {
        articles = catService.categories.map(Article.init(category:))
        applyFilter()
    }



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


    private static func fuzzy(src: String, pat: String) -> Bool {
        let s = src.lowercased(), p = pat.lowercased()
        var i = s.startIndex
        for ch in p {
            guard let found = s[i...].firstIndex(of: ch) else { return false }
            i = s.index(after: found)
        }
        return true
    }


    private var cancellables = Set<AnyCancellable>()
}
