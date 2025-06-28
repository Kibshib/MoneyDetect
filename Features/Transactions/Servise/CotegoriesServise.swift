//
//  CotegoriesServise.swift
//  MoneyDetector
//
//  Created by User on 11.06.2025.
//

import Foundation
final class CategoriesService {
    
    private let mockCategories: [Category] = [
        Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: true),
        Category(id: 2, name: "Продукты", emoji: "🛒", isIncome: false),
        Category(id: 3, name: "Кафе", emoji: "☕️", isIncome: false),
        Category(id: 4, name: "Фриланс", emoji: "🧑‍💻", isIncome: true)
    ]
    func getAllCategories() async throws -> [Category] {
        return mockCategories
    }
    func getExpenseIncome(direction : Direction) async throws -> [Category] {
        return mockCategories.filter({$0.direction == direction})
    }
    
}
