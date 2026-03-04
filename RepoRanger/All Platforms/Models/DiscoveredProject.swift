//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

enum ProjectKind: String, Codable, Hashable {
    case xcodeProject
    case swiftPackage

    var displayName: String {
        switch self {
        case .xcodeProject: "Xcode Project"
        case .swiftPackage: "Swift Package"
        }
    }
}

struct DiscoveredProject: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let kind: ProjectKind
    let url: URL
    let readmeURL: URL?

    var systemImage: String {
        switch kind {
        case .xcodeProject: "hammer.fill"
        case .swiftPackage: "shippingbox.fill"
        }
    }
}
