import SwiftUI

@main
struct ControleSocialApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
        }
    }
}
