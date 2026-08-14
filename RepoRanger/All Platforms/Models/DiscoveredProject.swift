//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftUI

enum ProjectKind: String, Codable, Hashable {
    case xcodeProject
    case swiftPackage
    case gitRepository

    var displayName: String {
        switch self {
        case .xcodeProject: "Xcode Project"
        case .swiftPackage: "Swift Package"
        case .gitRepository: "Git Repository"
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
    let isGitRepo: Bool

    var systemImage: String {
        switch kind {
        case .xcodeProject: "hammer.fill"
        case .swiftPackage: "shippingbox.fill"
        case .gitRepository: "arrow.triangle.branch"
        }
    }

    var stablePath: String {
        url.path(percentEncoded: false)
    }

    /// The directory the project lives in. For Xcode projects, `url` points at
    /// the `.xcodeproj` bundle itself, so the containing directory is used.
    nonisolated var directory: URL {
        switch kind {
        case .xcodeProject: url.deletingLastPathComponent()
        case .swiftPackage, .gitRepository: url
        }
    }

    var canOpenInXcode: Bool {
        switch kind {
        case .xcodeProject, .swiftPackage: true
        case .gitRepository: false
        }
    }

    var iconColor: Color {
        switch kind {
        case .xcodeProject: .blue
        case .swiftPackage: Color(red: 0xCA / 255.0, green: 0xA5 / 255.0, blue: 0x7C / 255.0)
        case .gitRepository: Color(red: 0xF0 / 255.0, green: 0x50 / 255.0, blue: 0x33 / 255.0)
        }
    }
}
