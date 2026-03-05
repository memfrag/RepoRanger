//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct MenuBarWindow: Scene {
    var body: some Scene {
        MenuBarExtra {
            MenuBarPopup()
                .appEnvironment(.default)
        } label: {
            Image(systemName: "shippingbox.fill")
        }
        .menuBarExtraStyle(.window)
        //.menuBarExtraStyle(.menu)
    }
}
