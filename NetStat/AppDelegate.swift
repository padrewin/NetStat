import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var cancellables = Set<AnyCancellable>()
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let netStatus = NetworkStatus()
        let contentView = ContentView(netStatus: netStatus, appDelegate: self)
        let hostingVC = BlurHostingView(rootView: contentView)

        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(named: "icon_offline")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        // Popover setup
        popover = NSPopover()
        popover.contentViewController = hostingVC
        popover.behavior = .applicationDefined

        netStatus.$currentConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let image = NSImage(named: netStatus.connectionAssetName)
                image?.isTemplate = true
                self?.statusItem.button?.image = image
            }
            .store(in: &cancellables)
    }
    
    /// Opens system network settings
    @objc func openNetworkSettings() {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        if version.majorVersion >= 15 || version.majorVersion <= 12 {
            // Sequoia sau Monterey și mai jos
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Ventura / Sonoma fallback
            let url = URL(fileURLWithPath: "/System/Applications/System Settings.app")
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            if let popoverWindow = popover.contentViewController?.view.window {
                popoverWindow.isOpaque = false
                popoverWindow.backgroundColor = .clear
                popoverWindow.hasShadow = true
            }
            
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.popover.performClose(nil)
                if let monitor = self?.eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    self?.eventMonitor = nil
                }
            }
        }
    }
}
