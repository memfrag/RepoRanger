//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import HotKey

extension Notification.Name {
    static let openCommandKBar = Notification.Name("OpenCommandKBar")
}

class MacAppDelegate: NSObject, NSApplicationDelegate {

    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKey = HotKey(key: .section, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                window.makeKeyAndOrderFront(nil)
            }
            NotificationCenter.default.post(name: .openCommandKBar, object: nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
