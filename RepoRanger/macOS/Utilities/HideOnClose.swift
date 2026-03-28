//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

/// Intercepts the window close to hide instead of destroy,
/// so the window can be reopened from the dock or a hotkey.
struct HideOnClose: NSViewRepresentable {

    private class HideTarget: NSObject {
        @objc func hideWindow(_ sender: Any?) {
            guard let button = sender as? NSButton else { return }
            button.window?.orderOut(nil)
        }
    }

    private static let hideTarget = HideTarget()

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.standardWindowButton(.closeButton)?.target = Self.hideTarget
            window.standardWindowButton(.closeButton)?.action = #selector(HideTarget.hideWindow(_:))
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
