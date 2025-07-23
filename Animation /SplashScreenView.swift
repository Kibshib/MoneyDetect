//
//  SplashScreenView.swift
//  MoneyDetector
//
//  Created by mac on 24.07.2025.
//

import SwiftUI

struct SplashScreenView<Content: View>: View {

    @Binding var isActive: Bool
    let content: () -> Content

    var body: some View {
        ZStack {
            if isActive {

                Color.white
                    .edgesIgnoringSafeArea(.all)
                LottieView(name: "pigIllustration") {

                    withAnimation {
                        isActive = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {

                content()
            }
        }
    }
}
