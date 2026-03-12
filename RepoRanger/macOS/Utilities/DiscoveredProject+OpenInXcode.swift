//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import AppKit

extension DiscoveredProject {

    func openInXcode() {
        let url = switch kind {
        case .xcodeProject: url
        case .swiftPackage: url.appendingPathComponent("Package.swift")
        }
        let xcodeURL = URL(filePath: "/Applications/Xcode.app")
        NSWorkspace.shared.open([url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
