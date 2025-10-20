import SwiftUI
import UIKit

// MARK: - Tab Bar Component
struct MiraTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tab.view
                    .tabItem {
                        image(for: selectedTab == index ? tab.selectedIcon : tab.icon)
                        Text(tab.title)
                    }
                    .tag(index)
            }
        }
        .accentColor(.oceanTeal)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func image(for icon: TabItem.IconType) -> Image {
        switch icon {
        case .system(let name):
            return Image(systemName: name)
        case .asset(let name):
            return Image(name).renderingMode(.original)
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = nil
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(.oceanTeal)
        ]

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = nil
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Tab Item Model
struct TabItem {
    enum IconType {
        case system(String)
        case asset(String)
    }

    let title: String
    let icon: IconType
    let selectedIcon: IconType
    let view: AnyView

    init<V: View>(
        title: String,
        icon: IconType,
        selectedIcon: IconType? = nil,
        @ViewBuilder view: () -> V
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.view = AnyView(view())
    }
}

// MARK: - Preview
private struct TabBarPreview: View {
    @State private var previewSelectedTab = 0

    var body: some View {
        MiraTabBar(
            selectedTab: $previewSelectedTab,
            tabs: [
                TabItem(
                    title: "Scan",
                    icon: .system("barcode.viewfinder")
                ) {
                    Text("Scanner View")
                },
                TabItem(
                    title: "History",
                    icon: .system("clock"),
                    selectedIcon: .system("clock.fill")
                ) {
                    Text("History View")
                },
                TabItem(
                    title: "Settings",
                    icon: .system("gearshape"),
                    selectedIcon: .system("gearshape.fill")
                ) {
                    Text("Settings View")
                }
            ]
        )
    }
}

#Preview {
    TabBarPreview()
}
