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
            Self.showMainWindow()
            NotificationCenter.default.post(name: .openCommandKBar, object: nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            Self.showMainWindow()
        }
        return false
    }

    static func showMainWindow() {
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        if let window = NSApplication.shared.windows.first(where: { $0.title == "RepoRanger" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
