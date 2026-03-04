//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

public struct SidebarSection: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var directoryIDs: [UUID]

    public init(id: UUID = UUID(), name: String, directoryIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.directoryIDs = directoryIDs
    }
}
