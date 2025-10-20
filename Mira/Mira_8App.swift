import SwiftUI

@main
struct MiraApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(appState: appState)
                }
            }
            .environmentObject(appState)
        }
    }
}
