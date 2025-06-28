// 4 дз
//  ArticlesView.swift
//  MoneyDetector
//
//  Created by mac on 28.06.2025.
//

import SwiftUI
import Combine
import Speech


// MARK: - Строка списка
private struct ArticleRow: View {
    let article: Article
    private var circleColor: Color { Color("AccentColor").opacity(0.15) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 32, height: 32)
                Text(article.icon)
                    .font(.system(size: 16))
            }
            .padding(.leading, 16)

            Text(article.title)
                .font(.system(size: 17))
                .padding(.leading, 5)

            Spacer()
        }
        .frame(height: 36)
    }
}

// MARK: - Кастомный SearchBar с фокусом
private struct SearchBar: View {
    @Binding var text: String
    @FocusState private var focused: Bool
    @StateObject private var recognizer = SpeechRecognizer()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focused)
                .submitLabel(.done)
            if !text.isEmpty {
                Button {
                    if recognizer.isRecording {
                        recognizer.stopRecording()
                        recognizer.isRecording = false
                    }
                    text = ""
                    } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            Button {
                recognizer.toggleRecording()
            } label: {
                Image(systemName:  "mic.fill")
                    .font(.system(size: 18))
            }
            .foregroundColor(recognizer.isRecording ? .blue : .secondary)
        }
        .padding(8)
        .background(Color(uiColor: .systemGray5))
        .cornerRadius(10)
        .onTapGesture { focused = true }

        // ← вот что добавляем, чтобы partial- и финальный текст сразу шел в SearchField
        .onChange(of: recognizer.transcript) { newTranscript in
            text = newTranscript
        }
    }
}
// MARK: - Экран
struct ArticlesView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        VStack(spacing: 10) {
            // Крупный заголовок
            Text("Мои статьи")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, maxHeight: 44, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 44) // отступ под статус-бар

            // Поиск
            SearchBar(text: $vm.searchText)
                .padding(.horizontal, 16)

            // Список
            List {
                Section(header: Text("СТАТЬИ")
                            .font(.caption)
                            .textCase(.uppercase)) {
                    ForEach(vm.filtered.indices, id: \ .self) { idx in
                        ArticleRow(article: vm.filtered[idx])
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                Rectangle()
                                    .fill(Color.white)
                                    .clipShape(
                                        RoundedCorner(corners: rowCorners(idx))
                                    )
                            )
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await vm.reload() }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rowCorners(_ index: Int) -> UIRectCorner {
        if vm.filtered.count == 1 { return .allCorners }
        if index == 0 { return [.topLeft, .topRight] }
        if index == vm.filtered.count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }
}


#Preview {
    NavigationStack { ArticlesView() }
}
