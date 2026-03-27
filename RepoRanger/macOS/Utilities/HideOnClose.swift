//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

/// Intercepts the window close to hide instead of destroy,
/// so the window can be reopened from the dock or a hotkey.
struct HideOnClose: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // Replace the close button action to hide instead of close
            window.standardWindowButton(.closeButton)?.target = context.coordinator
            window.standardWindowButton(.closeButton)?.action = #selector(Coordinator.hideWindow(_:))
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        @objc func hideWindow(_ sender: Any?) {
            guard let button = sender as? NSButton else { return }
            button.window?.orderOut(nil)
        }
    }
}
