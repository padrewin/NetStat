import SwiftUI

@main
struct NetStatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Eliminăm orice fereastră
        Settings {
            EmptyView()
        }
    }
}
