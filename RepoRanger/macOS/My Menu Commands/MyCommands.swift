//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct MyCommands: Commands {

    @FocusedValue(\.commandKBarToggle) var commandKBarToggle

    var body: some Commands {
        CommandMenu(Text("My Commands", comment: "My custom actions")) {
            Button {
                commandKBarToggle?.wrappedValue.toggle()
            } label: {
                Text("Quick Open", comment: "Open the quick project launcher.")
            }
            .keyboardShortcut("k", modifiers: [.command])

            Divider()

            Button {
                print("Build!")
            } label: {
                Text("Build", comment: "Build something or whatever.")
            }
            .keyboardShortcut("B", modifiers: [.command])

            Divider()

            Button {
                print("Do Stuff!")
            } label: {
                Text("Do Stuff", comment: "Do various types of stuff.")
            }
            .keyboardShortcut("D", modifiers: [.command])
        }
    }
}
