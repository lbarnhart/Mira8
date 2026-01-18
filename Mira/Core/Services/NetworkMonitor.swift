import Foundation
import Network
import Combine

/// Monitors network connectivity and publishes connection state changes
/// Use this to determine if the app should use cached data or fetch from network
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    /// Current connection status
    @Published private(set) var isConnected: Bool = true
    
    /// Type of connection (wifi, cellular, none)
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    /// Whether the connection is considered "expensive" (cellular data)
    @Published private(set) var isExpensive: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mira8.networkmonitor", qos: .utility)
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        case none = "No Connection"
    }
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
        AppLog.debug("NetworkMonitor: Started monitoring network connectivity", category: .general)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
        AppLog.debug("NetworkMonitor: Stopped monitoring network connectivity", category: .general)
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        // Log connection changes
        if wasConnected != isConnected {
            if isConnected {
                AppLog.info("NetworkMonitor: Connected via \(connectionType.rawValue)", category: .general)
            } else {
                AppLog.warning("NetworkMonitor: Disconnected - switching to offline mode", category: .general)
            }
        }
    }
    
    /// Check if we have a fast connection suitable for prefetching
    var hasFastConnection: Bool {
        isConnected && connectionType == .wifi && !isExpensive
    }
    
    /// Convenience method to check connection and log if offline
    func checkConnectionOrLog() -> Bool {
        if !isConnected {
            AppLog.debug("NetworkMonitor: Offline - using cached data", category: .general)
        }
        return isConnected
    }
}

// MARK: - SwiftUI Environment Support

import SwiftUI

private struct NetworkMonitorKey: EnvironmentKey {
    static let defaultValue: NetworkMonitor = .shared
}

extension EnvironmentValues {
    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}

extension View {
    /// Adds an offline banner overlay when network is unavailable
    func offlineAware() -> some View {
        modifier(OfflineAwareModifier())
    }
}

struct OfflineAwareModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected {
                    OfflineBannerView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

/// Simple offline banner shown when network is unavailable
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.subheadline.weight(.semibold))
            
            Text("Working offline")
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Text("Using cached data")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.warning)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
    }
}

#Preview("Offline Banner") {
    VStack {
        OfflineBannerView()
        Spacer()
    }
}
