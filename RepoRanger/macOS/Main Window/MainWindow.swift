//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox
import Sparkle

struct MainWindow: Scene {

    let updater: SPUUpdater

    var body: some Scene {

        WindowGroup {
            Sidebar()
                .frame(minWidth: 700, minHeight: 400)
                .background(AlwaysOnTop())
                .background(HideOnClose())
                .appEnvironment(.default)
        }
        .commands {
            AboutCommand()
            SidebarCommands()
            ExportCommands()
            AlwaysOnTopCommand()
            CheckForUpdatesCommand(updater: updater)
            HelpCommands()
            
            /// Add a menu with custom commands
            MyCommands()
            
            // Remove the "New Window" option from the File menu.
            CommandGroup(replacing: .newItem, addition: { })
        }
        
    }
}
