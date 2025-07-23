

import SwiftUI
@main
struct MyApp: App {
    @State private var showSplash = true 

    var body: some Scene {
        WindowGroup {
            SplashScreenView(isActive: $showSplash) {
                RootTabView()
            }
        }
    }
}
