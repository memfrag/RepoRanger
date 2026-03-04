//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct EmptyPane: View {
    var body: some View {
        Pane {
            VStack {
                Text("Select a project to view its README")
            }
        }
    }
}

struct EmptyPane_Previews: PreviewProvider {
    static var previews: some View {
        EmptyPane()
    }
}
