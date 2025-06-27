// Currency.swift
import Foundation

enum Currency: String, CaseIterable, Identifiable {
    case rub = "RUB", usd = "USD", eur = "EUR"
    var id: Self { self }

    var title: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Американский доллар $"
        case .eur: return "Евро €"
        }
    }

    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}
