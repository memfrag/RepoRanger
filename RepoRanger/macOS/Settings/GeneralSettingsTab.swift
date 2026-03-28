//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct GeneralSettingsTab: View {

    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
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
