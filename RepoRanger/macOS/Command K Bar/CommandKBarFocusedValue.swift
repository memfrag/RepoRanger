//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct CommandKBarToggleKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var commandKBarToggle: Binding<Bool>? {
        get { self[CommandKBarToggleKey.self] }
        set { self[CommandKBarToggleKey.self] = newValue }
    }
}
