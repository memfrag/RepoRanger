//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import HotKey

struct GeneralSettingsTab: View {

    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                HStack {
                    Text("Global Shortcut:")
                    Spacer()
                    ShortcutRecorder(
                        keyCode: $settings.hotkeyKeyCode,
                        modifiers: $settings.hotkeyModifiers
                    )
                }
                Text("System-wide shortcut to bring RepoRanger to front and open Quick Find.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Git Client Path:", text: $settings.gitClientPath)
                Text("Path to the command-line tool used to open project directories (e.g. stree, fork, tower).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}

private struct ShortcutRecorder: View {

    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32

    @State private var isRecording = false
    @State private var monitor: Any?

    private var displayString: String {
        let combo = KeyCombo(carbonKeyCode: keyCode, carbonModifiers: modifiers)
        let desc = combo.description
        return desc.isEmpty ? "Click to record" : desc
    }

    var body: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            Text(isRecording ? "Press shortcut…" : displayString)
                .frame(minWidth: 100)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isRecording ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard !flags.isEmpty else { return event }

            let combo = KeyCombo(
                carbonKeyCode: UInt32(event.keyCode),
                carbonModifiers: flags.carbonFlags
            )
            guard combo.key != nil else { return event }

            keyCode = combo.carbonKeyCode
            modifiers = combo.carbonModifiers
            stopRecording()

            NotificationCenter.default.post(
                name: Notification.Name("HotkeySettingsChanged"),
                object: nil
            )

            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
