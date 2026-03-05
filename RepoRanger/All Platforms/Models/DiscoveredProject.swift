//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftUI

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
    let parentName: String

    var systemImage: String {
        switch kind {
        case .xcodeProject: "hammer.fill"
        case .swiftPackage: "shippingbox.fill"
        }
    }

    var stablePath: String { url.path(percentEncoded: false) }

    var iconColor: Color {
        switch kind {
        case .xcodeProject: .blue
        case .swiftPackage: Color(red: 0xCA / 255.0, green: 0xA5 / 255.0, blue: 0x7C / 255.0)
        }
    }
}
