import SwiftUI

@main
struct MiraApp: App {
    @StateObject private var appState: AppState

    init() {
        let launchConfiguration = AppLaunchConfiguration.current
        launchConfiguration.prepare()

        let state = AppState()
        if let initialTab = launchConfiguration.initialTab {
            state.selectedTab = initialTab.rawValue
        }

        _appState = StateObject(wrappedValue: state)
    }

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
