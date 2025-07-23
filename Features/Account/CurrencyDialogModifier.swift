import SwiftUI


struct CurrencyDialogModifier: ViewModifier {
    @Binding var show: Bool
    @Binding var selection: Currency

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Выберите валюту",
                                isPresented: $show,
                                titleVisibility: .visible) {
                ForEach(Currency.allCases, id: \.self) { cur in
                    Button(cur.symbol) {
                        selection = cur
                    }
                }
                Button("Отмена", role: .cancel) { }
            }
    }
}


extension View {
    func currencyDialog(show: Binding<Bool>,
                        selection: Binding<Currency>) -> some View {
        modifier(CurrencyDialogModifier(show: show, selection: selection))
    }
}
