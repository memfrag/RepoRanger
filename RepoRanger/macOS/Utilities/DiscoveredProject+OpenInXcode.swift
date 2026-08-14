//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import AppKit

extension DiscoveredProject {

    func openInXcode() {
        guard canOpenInXcode else { return }
        let url = switch kind {
        case .xcodeProject: url
        case .swiftPackage: url.appendingPathComponent("Package.swift")
        case .gitRepository: url
        }
        let xcodeURL = URL(filePath: "/Applications/Xcode.app")
        NSWorkspace.shared.open([url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
