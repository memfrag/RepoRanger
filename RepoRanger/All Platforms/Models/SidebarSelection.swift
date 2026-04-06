//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

enum SidebarSelection: Hashable {
    case directory(MonitoredDirectory)
    case recentCollection
    case customCollection(ProjectCollection)
}
