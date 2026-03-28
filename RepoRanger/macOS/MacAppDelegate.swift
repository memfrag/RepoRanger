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
    private var observations: [NSKeyValueObservation] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerHotKey()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: Notification.Name("HotkeySettingsChanged"),
            object: nil
        )
    }

    @objc private func hotkeySettingsChanged() {
        registerHotKey()
    }

    private func registerHotKey() {
        let settings = AppEnvironment.default.appSettings
        let combo = KeyCombo(
            carbonKeyCode: settings.hotkeyKeyCode,
            carbonModifiers: settings.hotkeyModifiers
        )
        hotKey = HotKey(keyCombo: combo)
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
        NSRunningApplication.current.activate()
        if let window = NSApplication.shared.windows.first(where: { $0.title == "RepoRanger" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
