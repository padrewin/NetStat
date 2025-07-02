import SwiftUI

@main
struct NetStatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menține fereastra goală
        Settings {
            EmptyView()
        }
        // Aici adaugi comenzile
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit NetStat") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Open Network Settings") {
                    appDelegate.openNetworkSettings()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
