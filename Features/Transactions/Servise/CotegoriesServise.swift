import Foundation
import Combine

@MainActor
final class CotegoriesServise: ObservableObject {
    static let shared = CotegoriesServise()

    @Published private(set) var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = NetworkClient.shared
    private init() {}

    func loadCategories(force: Bool = false) async {
        if !force && !categories.isEmpty { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let dtos: [CategoryResponse] = try await client.request(
                Endpoint(path: "/categories")
            )
            categories = dtos.map(mapCategory(from:))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func category(id: Int) -> Category? { categories.first { $0.id == id } }
    func incomeCategories() -> [Category] { categories.filter { $0.isIncome } }
    func expenseCategories() -> [Category] { categories.filter { !$0.isIncome } }
}

// MARK: - API decode (приватно)

private struct CategoryResponse: Decodable {
    let id: Int
    let name: String
    let emoji: String?
    let isIncome: Bool
}

// MARK: - Mapping

private extension CotegoriesServise {
    func mapCategory(from dto: CategoryResponse) -> Category {
        Category(
            id: dto.id,
            name: dto.name,
            emoji: dto.emoji ?? "",
            isIncome: dto.isIncome
        )
    }
}
