import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        MiraTabBar(
            selectedTab: $selectedTab,
            tabs: [
                TabItem(
                    title: "Scan",
                    icon: .system("barcode.viewfinder"),
                    selectedIcon: .system("barcode.viewfinder")
                ) {
                    LiveScannerView()
                },
                TabItem(
                    title: "History",
                    icon: .system("clock"),
                    selectedIcon: .system("clock.fill")
                ) {
                    HistoryView()
                },
                TabItem(
                    title: "Favorites",
                    icon: .system("heart"),
                    selectedIcon: .system("heart.fill")
                ) {
                    FavoritesView()
                },
                TabItem(
                    title: "Profile",
                    icon: .system("person.crop.circle"),
                    selectedIcon: .system("person.crop.circle.fill")
                ) {
                    ProfileView()
                }
            ]
        )
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
