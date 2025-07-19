//
//  ArticlesView.swift
//  MoneyDetector
//

import SwiftUI
import Speech

// MARK: – Строка списка
private struct ArticleRow: View {
    let article: Article
    private var circleColor: Color { Color("AccentColor").opacity(0.15) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(circleColor).frame(width: 32, height: 32)
                Text(article.icon).font(.system(size: 16))
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

// MARK: – Кастомный SearchBar
private struct SearchBar: View {
    @Binding var text: String
    @FocusState private var focused: Bool
    @StateObject private var recognizer = SpeechRecognizer()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)

            TextField("Search", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focused)           // фокус для «Done»
                .submitLabel(.done)

            if !text.isEmpty {
                Button {
                    recognizer.stopRecording()
                    recognizer.isRecording = false
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }

            Button { recognizer.toggleRecording() } label: {
                Image(systemName: "mic.fill")
            }
            .font(.system(size: 18))
            .foregroundColor(recognizer.isRecording ? .blue : .secondary)
        }
        .padding(8)
        .background(Color(uiColor: .systemGray5))
        .cornerRadius(10)
        .onTapGesture { focused = true }
        // подставляем распознанный текст
        .onChange(of: recognizer.transcript) { text = $0 }
    }
}

// MARK: – Экран
struct ArticlesView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        VStack(spacing: 10) {

            // Заголовок
            Text("Мои статьи")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, maxHeight: 44, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 44)

            // Поисковая строка
            SearchBar(text: $vm.searchText)
                .padding(.horizontal, 16)

            // Список
            List {
                Section(header: Text("СТАТЬИ")
                            .font(.caption)
                            .textCase(.uppercase)) {

                    ForEach(vm.filtered, id: \.id) { art in
                        ArticleRow(article: art)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                Rectangle()
                                    .fill(Color.white)
                                    .clipShape(RoundedCorner(corners: rowCorners(art)))
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

    // MARK: – углы
    private func rowCorners(_ art: Article) -> UIRectCorner {
        if vm.filtered.count == 1 { return .allCorners }
        if art.id == vm.filtered.first?.id   { return [.topLeft, .topRight] }
        if art.id == vm.filtered.last?.id    { return [.bottomLeft, .bottomRight] }
        return []
    }
}

#if DEBUG
struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ArticlesView() }
    }
}
#endif
