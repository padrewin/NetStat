import Foundation
import Network
import CoreWLAN

enum ConnectionType {
    case wifi(name: String)
    case ethernet
    case offline
}

class NetworkStatus: ObservableObject {
    @Published var currentConnection: ConnectionType = .offline
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        // Încearcă să obții SSID
                        let ssid = CWWiFiClient.shared().interface()?.ssid() ?? "Connected"
                        self?.currentConnection = .wifi(name: ssid)
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        self?.currentConnection = .ethernet
                    } else {
                        self?.currentConnection = .offline
                    }
                } else {
                    self?.currentConnection = .offline
                }
            }
        }

        monitor.start(queue: queue)
    }
}
