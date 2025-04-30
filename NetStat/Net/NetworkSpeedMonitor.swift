import Foundation
import Combine

class NetworkSpeedMonitor: ObservableObject {
    @Published var downloadHistory: [Double] = []
    @Published var uploadHistory: [Double] = []

    private var timer: Timer?
    private var lastReceived: UInt64 = 0
    private var lastSent: UInt64 = 0
    private let maxSamples = 60

    init() {
        downloadHistory = Array(repeating: 0, count: maxSamples)
        uploadHistory = Array(repeating: 0, count: maxSamples)
        updateInitialData()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.measureSpeeds()
        }
    }

    private func updateInitialData() {
        let (recv, sent) = getInterfaceBytes()
        lastReceived = recv
        lastSent = sent
    }

    private func measureSpeeds() {
        let (currentReceived, currentSent) = getInterfaceBytes()

        let recvDiff = currentReceived >= lastReceived ? currentReceived - lastReceived : 0
        let sentDiff = currentSent >= lastSent ? currentSent - lastSent : 0

        let deltaDownload = (Double(recvDiff) * 8) / 1_000_000
        let deltaUpload = (Double(sentDiff) * 8) / 1_000_000

        DispatchQueue.main.async {
            if self.downloadHistory.count >= self.maxSamples {
                self.downloadHistory.removeFirst()
            }
            if self.uploadHistory.count >= self.maxSamples {
                self.uploadHistory.removeFirst()
            }

            self.downloadHistory.append(deltaDownload)
            self.uploadHistory.append(deltaUpload)
        }

        lastReceived = currentReceived
        lastSent = currentSent
    }

    private func getInterfaceBytes() -> (UInt64, UInt64) {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0

        let validPrefixes = ["en", "bridge", "pdp_ip", "utun", "awdl"]

        if getifaddrs(&ifaddrPtr) == 0 {
            var ptr = ifaddrPtr
            while ptr != nil {
                if let interface = ptr?.pointee,
                   let namePtr = interface.ifa_name,
                   interface.ifa_data != nil {
                    let name = String(cString: namePtr)
                    // print("Interface: \(name)")

                    if validPrefixes.contains(where: { name.hasPrefix($0) }) {
                        let data = unsafeBitCast(interface.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                        totalReceived += UInt64(data.pointee.ifi_ibytes)
                        totalSent += UInt64(data.pointee.ifi_obytes)
                    }
                }
                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddrPtr)
        }

        return (totalReceived, totalSent)
    }

    deinit {
        timer?.invalidate()
    }
}
