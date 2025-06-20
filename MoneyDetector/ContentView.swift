//
//  //ContentView.swift
//  //MoneyDetector
//
//  //Created by User on 10.06.2025.
//
//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack(spacing: 22) {
//            VStack(alignment: .center, spacing: 0) { // spacing: 0 убирает лишние промежутки
//                // Заголовок
//                Image("History")
//                    .renderingMode(.template)
//                    .foregroundColor(Color("ForHistory"))
//                    .frame(maxWidth: .infinity , maxHeight: 44 , alignment: .trailing )
//                //                        .padding(.top, 10)
//                    .padding(.horizontal , 16)
//
//                Text("Расходы сегодня")
//                    .font(.system(size: 34, weight: .bold))
//                    .padding(.horizontal , 16)
//                    .frame(maxWidth: .infinity , maxHeight: 52 , alignment: .leading )
//                // Блок с общей суммой
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.white)
//                    .frame(height: 44)
//                    .overlay(
//                        HStack {
//                            Text("Всего")
//                                .font(.system(size: 17))
//                                .foregroundColor(.black)
//
//                            Spacer() // Прижимает сумму к правому краю
//
//                            Text("500")
//                                .font(.system(size: 17, weight: .bold))
//                                .foregroundColor(.black)
//                        }
//                            .padding(.horizontal, 16)
//                    )
//                    .padding(.horizontal , 16 )
//                    .padding(.top, 8)
//
//                Spacer() // Прижимает весь контент выше к верху
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Выравнивание по верху
//            .background(Color(.systemGroupedBackground))
//
//
//        }
//    }
//}
//    struct ContentView_Previews: PreviewProvider {
//            static var previews: some View {
//            ContentView()
//        }
//    }
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        MainTabView()
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//

