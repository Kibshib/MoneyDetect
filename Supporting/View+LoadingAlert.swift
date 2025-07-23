//
//  View+LoadingAlert.swift
//  MoneyDetector
//
//  Created by mac on 17.07.2025.
//

import SwiftUI

extension View {
    func overlayLoading(_ isLoading: Bool) -> some View {
        ZStack {
            self
            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView("Загрузка…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    func errorAlert(message: Binding<String?>) -> some View {
        alert("Ошибка", isPresented: .init(
            get: { message.wrappedValue != nil },
            set: { _ in message.wrappedValue = nil }
        )) {
            Button("OK", role: .cancel) { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
