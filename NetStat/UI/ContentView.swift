import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var netStatus: NetworkStatus
    @StateObject var speedMonitor = NetworkSpeedMonitor()
    let appDelegate: AppDelegate

    var isOffline: Bool {
        if case .offline = netStatus.currentConnection {
            return true
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + status
            HStack {
                Image(nsImage: NSImage(named: netStatus.connectionAssetName) ?? NSImage())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(netStatus.connectionText)
                    .font(.headline)
            }

            // Graph
            NetworkGraphView(
                downloadSpeeds: speedMonitor.downloadHistory,
                uploadSpeeds: speedMonitor.uploadHistory,
                isOffline: isOffline
            )
            
            Divider()
                .background(Color.secondary.opacity(0.3))
                .padding(.top, 4)

            // Open Network Settings
            Button(action: {
                appDelegate.openNetworkSettings()
            }) {
                HStack {
                    Text("Open Network Settings")
                    Spacer()
                    Text("⌘N")
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 2)
            
            // Quit
            Button(action: {
                NSApp.terminate(nil)
            }) {
                HStack {
                    Text("Quit NetStat")
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 2)
        }
        .padding()
        .frame(width: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension NetworkStatus {
    var connectionAssetName: String {
        switch currentConnection {
        case .wifi:      return "icon_wifi"
        case .ethernet:  return "icon_ethernet"
        case .hotspot:   return "icon_hotspot"    // ← hotspot image
        case .offline:   return "icon_offline"
        }
    }

    var connectionText: String {
        switch currentConnection {
        case .wifi:
            return "Wi-Fi connection"
        case .hotspot:
            return "Hotspot connection"         // or “Personal Hotspot”
        case .ethernet:
            return "Ethernet connection"
        case .offline:
            return "Disconnected"
        }
    }
}
