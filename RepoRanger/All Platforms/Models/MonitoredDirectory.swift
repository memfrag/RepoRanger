//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

public struct MonitoredDirectory: Codable, Identifiable, Hashable {
    public let id: UUID
    public let path: String
    public let displayName: String
    public let bookmarkData: Data

    public init(id: UUID = UUID(), url: URL) throws {
        self.id = id
        self.path = url.path(percentEncoded: false)
        self.displayName = url.lastPathComponent
        self.bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Resolves the security-scoped bookmark and returns an accessible URL.
    /// Calls `startAccessingSecurityScopedResource()` on the resolved URL.
    /// The caller is responsible for calling `stopAccessingSecurityScopedResource()` when done.
    public func resolveURL() -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        return url
    }
}
