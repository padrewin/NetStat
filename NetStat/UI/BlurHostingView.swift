//
//  BlurHostingView.swift
//  NetStat
//
//  Created by padrewin-mac on 30.04.2025.
//

import SwiftUI

class BlurHostingView<Content: View>: NSViewController {
    private let rootView: Content

    init(rootView: Content) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .popover
        blurView.state = .active

        // Adaugă overlay semi-transparent pentru lizibilitate mai bună
        let overlay = NSView()
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor.windowBackgroundColor
            .withAlphaComponent(0.2) // poți ajusta între 0.1 - 0.3 după preferințe
            .cgColor
        overlay.translatesAutoresizingMaskIntoConstraints = false

        blurView.addSubview(overlay)
        blurView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: blurView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),

            hostingView.topAnchor.constraint(equalTo: blurView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor)
        ])

        self.view = blurView
    }
}
