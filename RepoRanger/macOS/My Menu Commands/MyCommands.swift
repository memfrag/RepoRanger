//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct MyCommands: Commands {

    @FocusedValue(\.commandKBarToggle) var commandKBarToggle

    var body: some Commands {
        CommandMenu(Text("Go", comment: "Navigation actions")) {
            Button {
                commandKBarToggle?.wrappedValue.toggle()
            } label: {
                Text("Quick Open", comment: "Open the quick project launcher.")
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
    }
}
