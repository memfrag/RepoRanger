//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

enum ProjectMetadataExtractor {

    static func extract(from project: DiscoveredProject) async -> ProjectMetadata {
        var swiftToolsVersion: String?
        var deploymentTargets: [String] = []
        let hasUncommittedChanges: Bool

        if project.kind == .swiftPackage {
            let packageURL = project.url.appendingPathComponent("Package.swift")
            if let contents = try? String(contentsOf: packageURL, encoding: .utf8) {
                swiftToolsVersion = parseToolsVersion(from: contents)
                deploymentTargets = parseDeploymentTargets(from: contents)
            }
        }

        let projectDirectory: URL = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        hasUncommittedChanges = await checkGitStatus(in: projectDirectory)
        let license = LicenseDetector.detect(in: projectDirectory)?.identifier

        return ProjectMetadata(
            swiftToolsVersion: swiftToolsVersion,
            deploymentTargets: deploymentTargets,
            hasUncommittedChanges: hasUncommittedChanges,
            license: license
        )
    }

    private static func parseToolsVersion(from contents: String) -> String? {
        guard let firstLine = contents.components(separatedBy: .newlines).first else {
            return nil
        }
        let pattern = #"//\s*swift-tools-version:\s*(\S+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: firstLine, range: NSRange(firstLine.startIndex..., in: firstLine)),
              let range = Range(match.range(at: 1), in: firstLine) else {
            return nil
        }
        return String(firstLine[range])
    }

    private static func parseDeploymentTargets(from contents: String) -> [String] {
        let pattern = #"\.(macOS|iOS|tvOS|watchOS|visionOS|macCatalyst)\(\s*(?:\.v(\d+(?:_\d+)?)|"([^"]+)")\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(contents.startIndex..., in: contents)
        let matches = regex.matches(in: contents, range: range)
        return matches.compactMap { match in
            guard let platformRange = Range(match.range(at: 1), in: contents) else { return nil }
            let platform = String(contents[platformRange])
            if let vRange = Range(match.range(at: 2), in: contents) {
                let version = String(contents[vRange]).replacingOccurrences(of: "_", with: ".")
                return "\(platform) \(version)"
            } else if let strRange = Range(match.range(at: 3), in: contents) {
                return "\(platform) \(contents[strRange])"
            }
            return nil
        }
    }

    private static func checkGitStatus(in directory: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(filePath: "/usr/bin/git")
                process.arguments = ["status", "--porcelain"]
                process.currentDirectoryURL = directory
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
