//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

enum DirectoryScanner {

    static func scan(directory: URL) async -> [DiscoveredProject] {
        let dir = directory
        return await Task.detached {
            scanDirectory(dir)
        }.value
    }

    private nonisolated static func scanDirectory(_ directory: URL) -> [DiscoveredProject] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var projects: [DiscoveredProject] = []
        var xcodeProjectDirs: Set<String> = []

        while let url = enumerator.nextObject() as? URL {
            let pathExtension = url.pathExtension.lowercased()
            let lastComponent = url.lastPathComponent

            // Skip anything nested under a directory that already has an Xcode project
            let urlPath = url.path(percentEncoded: false)
            if xcodeProjectDirs.contains(where: { urlPath.hasPrefix($0) }) {
                enumerator.skipDescendants()
                continue
            }

            if pathExtension == "xcodeproj" {
                let projectDir = url.deletingLastPathComponent()
                let name = url.deletingPathExtension().lastPathComponent
                let readmeURL = findReadme(in: projectDir)
                projects.append(DiscoveredProject(
                    name: name,
                    kind: .xcodeProject,
                    url: url,
                    readmeURL: readmeURL,
                    parentName: projectDir.lastPathComponent
                ))
                xcodeProjectDirs.insert(projectDir.path(percentEncoded: false))
                enumerator.skipDescendants()
            } else if lastComponent == "Package.swift" {
                let packageDir = url.deletingLastPathComponent()
                let name = packageDir.lastPathComponent
                let readmeURL = findReadme(in: packageDir)
                projects.append(DiscoveredProject(
                    name: name,
                    kind: .swiftPackage,
                    url: packageDir,
                    readmeURL: readmeURL,
                    parentName: packageDir.deletingLastPathComponent().lastPathComponent
                ))
                enumerator.skipDescendants()
            }
        }

        // Remove packages/subprojects that were found before their parent .xcodeproj
        let filteredProjects = projects.filter { project in
            guard project.kind != .xcodeProject else { return true }
            let projectPath = project.url.path(percentEncoded: false)
            return !xcodeProjectDirs.contains(where: { projectPath.hasPrefix($0) })
        }

        return filteredProjects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private nonisolated static func findReadme(in directory: URL) -> URL? {
        let candidates = ["README.md", "readme.md", "Readme.md", "README.MD"]
        for candidate in candidates {
            let url = directory.appendingPathComponent(candidate)
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                return url
            }
        }
        return nil
    }
}
