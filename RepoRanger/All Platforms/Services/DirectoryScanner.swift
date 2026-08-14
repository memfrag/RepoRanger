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

        // Outermost git repository roots, in the order they are encountered.
        var gitRepoRoots: [String] = []
        if isGitRepository(directory) {
            gitRepoRoots.append(directoryPath(of: directory))
        }

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
                    parentName: projectDir.lastPathComponent,
                    isGitRepo: isGitRepository(projectDir)
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
                    parentName: packageDir.deletingLastPathComponent().lastPathComponent,
                    isGitRepo: isGitRepository(packageDir)
                ))
                enumerator.skipDescendants()
            } else if isDirectory(url),
                      !gitRepoRoots.contains(where: { urlPath.hasPrefix($0 + "/") }),
                      isGitRepository(url) {
                // Keep descending, so Xcode projects and packages inside the
                // repository are still discovered. Nested repositories, such as
                // submodules, are not listed separately.
                gitRepoRoots.append(directoryPath(of: url))
            }
        }

        // Remove packages/subprojects that were found before their parent .xcodeproj
        var filteredProjects = projects.filter { project in
            guard project.kind != .xcodeProject else { return true }
            let projectPath = project.url.path(percentEncoded: false)
            return !xcodeProjectDirs.contains(where: { projectPath.hasPrefix($0) })
        }

        // A git repository is only listed in its own right if it does not
        // already appear as an Xcode project or a Swift package.
        let projectPaths = filteredProjects.map { directoryPath(of: $0.directory) }
        for root in gitRepoRoots {
            guard !projectPaths.contains(where: { $0 == root || $0.hasPrefix(root + "/") }) else {
                continue
            }
            let rootURL = URL(filePath: root, directoryHint: .isDirectory)
            filteredProjects.append(DiscoveredProject(
                name: rootURL.lastPathComponent,
                kind: .gitRepository,
                url: rootURL,
                readmeURL: findReadme(in: rootURL),
                parentName: rootURL.deletingLastPathComponent().lastPathComponent,
                isGitRepo: true
            ))
        }

        return filteredProjects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// `path(percentEncoded:)` keeps the trailing slash on a directory URL,
    /// which would break the prefix comparisons, so it is trimmed off here.
    private nonisolated static func directoryPath(of url: URL) -> String {
        let path = url.path(percentEncoded: false)
        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }

    private nonisolated static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    /// A `.git` entry is a directory in a normal clone, but a file in a
    /// submodule or a linked worktree, so existence is all that is checked.
    private nonisolated static func isGitRepository(_ directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appendingPathComponent(".git").path(percentEncoded: false)
        )
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
