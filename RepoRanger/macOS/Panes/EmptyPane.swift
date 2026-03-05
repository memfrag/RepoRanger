//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct EmptyPane: View {
    var body: some View {
        Pane {
            VStack {
                Image("RepoRangerRacoon")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(.black)
                    .opacity(0.2)
                    .blendMode(.darken)
            }
        }
    }
}

struct EmptyPane_Previews: PreviewProvider {
    static var previews: some View {
        EmptyPane()
    }
}
