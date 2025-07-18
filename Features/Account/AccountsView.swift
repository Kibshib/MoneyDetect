//
//  AccountsView.swift
//  MoneyDetector
//

import SwiftUI

struct AccountsView: View {
    @StateObject private var vm = BankAccountViewModel()
    @State private var inEdit = false
    @FocusState private var isFocused: Bool
    @State private var showCurrencyDialog = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Кнопка редактирования / сохранения
                    HStack(spacing: 0) {
                        Spacer()
                        Button(inEdit ? "Сохранить" : "Редактировать") {
                            if inEdit {
                                vm.save()
                                inEdit = false
                            } else {
                                inEdit = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isFocused = true
                                }
                            }
                        }
                        .disabled(vm.isSaving || vm.isLoadingFromService)
                        .foregroundColor(Color("ForHistory"))
                        .frame(height: 44)
                        .padding(.trailing, 16)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Мой счет")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, maxHeight: 44, alignment: .leading)
                        .padding(.horizontal, 16)

                    // Баланс
                    HStack {
                        Image("MoneyIcon")
                            .frame(width: 22, height: 22)
                        Text("Баланс")
                        Spacer()

                        if inEdit {
                            TextField("0", text: $vm.balanceString)
                                .keyboardType(.decimalPad)
                                .focused($isFocused)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.plain)
                                .accentColor(.purple)
                                .frame(width: 120)
                                .onChange(of: vm.balanceString) { newValue in
                                    // оставить только цифры и запятую/точку
                                    let filtered = newValue.filter { $0.isNumber || $0 == "," || $0 == "." }
                                    if filtered != newValue {
                                        vm.balanceString = filtered
                                    }
                                }
                        } else {
                            // Отрисовка скрывающей шторки
                            let charCount = vm.formattedBalance.count + 1
                            let charWidth: CGFloat = 8
                            let padding: CGFloat = 16
                            let spoilerWidth = CGFloat(charCount) * charWidth + padding
                            let spoilerHeight: CGFloat = 24

                            ZStack(alignment: .trailing) {
                                Text(vm.formattedBalance + " " + vm.currency.symbol)
                                    .bold()
                                    .foregroundColor(.black)
                                    .frame(width: spoilerWidth, alignment: .trailing)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                if vm.isBalanceHidden {
                                    Color("AccentColor").opacity(0.1)
                                        .frame(width: spoilerWidth, height: 44)
                                        .cornerRadius(16)
                                    VisualEffectView(blurStyle: .systemUltraThinMaterial)
                                        .frame(width: spoilerWidth, height: spoilerHeight)
                                        .cornerRadius(16)
                                        .allowsHitTesting(false)
                                }

                                SpoilerViewRepresentable(
                                    isHidden: $vm.isBalanceHidden,
                                    size: CGSize(width: spoilerWidth, height: spoilerHeight)
                                )
                                .frame(width: spoilerWidth, height: spoilerHeight)
                                .allowsHitTesting(false)
                            }
                            .animation(.easeInOut(duration: 0.3), value: vm.isBalanceHidden)
                            .onTapGesture {
                                withAnimation { vm.isBalanceHidden = false }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(inEdit ? Color.white : Color("AccentColor"))
                    .cornerRadius(16)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                    // Валюта
                    HStack {
                        Text("Валюта")
                        Spacer()
                        if inEdit {
                            Button {
                                showCurrencyDialog = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(vm.currency.symbol)
                                        .bold()
                                        .foregroundColor(.black)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            Text(vm.currency.symbol)
                                .bold()
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(inEdit ? Color.white : Color("AccentColorWithOpacity"))
                    .cornerRadius(16)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 20)
                }
                .hideKeyboardOnTap()
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            // Pull to refresh
            .refreshable {
                await vm.refresh()
            }
            // Выбор валюты
            .confirmationDialog("Выберите валюту",
                                isPresented: $showCurrencyDialog,
                                titleVisibility: .visible) {
                ForEach(Currency.allCases, id: \.self) { cur in
                    Button(cur.symbol) {
                        vm.currency = cur
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
            .navigationBarHidden(true)
            // Shake detector (скрыть/показать баланс)
            .background(
                ShakeDetector {
                    withAnimation(.easeInOut) {
                        vm.isBalanceHidden.toggle()
                    }
                }
                .allowsHitTesting(false)
            )
        }
        // индикатор + алерт из сервиса
        .overlayLoading(vm.isLoadingFromService)
        .errorAlert(message: Binding(
            get: { vm.serviceError },
            set: { _ in vm.serviceError = nil }
        ))
        // первая загрузка
        .task {
            await vm.load()
        }
    }
}
