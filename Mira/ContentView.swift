import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        MiraTabBar(
            selectedTab: $appState.selectedTab,
            tabs: [
                TabItem(
                    title: "Scan",
                    icon: .system("barcode.viewfinder"),
                    selectedIcon: .system("barcode.viewfinder")
                ) {
                    LiveScannerView()
                },
                TabItem(
                    title: "Search",
                    icon: .system("magnifyingglass"),
                    selectedIcon: .system("magnifyingglass")
                ) {
                    NLSearchView()
                },
                TabItem(
                    title: "Insights",
                    icon: .system("chart.bar"),
                    selectedIcon: .system("chart.bar.fill")
                ) {
                    InsightsView()
                },
                TabItem(
                    title: "History",
                    icon: .system("clock"),
                    selectedIcon: .system("clock.fill")
                ) {
                    HistoryView()
                },
                TabItem(
                    title: "List",
                    icon: .system("cart"),
                    selectedIcon: .system("cart.fill")
                ) {
                    ShoppingListView()
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
