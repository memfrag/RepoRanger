//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import KeyValueStore

// MARK: - AppSettings

/// A container for application-wide user settings.
///
/// `AppSettings` provides observable properties that represent user preferences
/// and persists them using an underlying key–value store.
/// It is designed to be injected into SwiftUI views and other components
/// that depend on reactive settings.
///
@Observable @MainActor public final class AppSettings {

    // MARK: Key

    /// The keys used to store and retrieve settings from the underlying store.
    public enum Key: String {
        /// The preferred color scheme for the app.
        case colorScheme
        
        case monitoredDirectories
        case sidebarSections
        case favoriteProjectPaths
        case projectSortOrder
        case recentProjectPaths
        case gitClientPath
        case hotkeyKeyCode
        case hotkeyModifiers
        case projectTags
        case availableTags
        case collections
    }

    // MARK: Properties

    /// The app's current color scheme preference.
    public var colorScheme: AppColorScheme {
        didSet {
            store.save(colorScheme, for: .colorScheme)
        }
    }
    
    public var monitoredDirectories: [MonitoredDirectory] {
        didSet {
            store.save(monitoredDirectories, for: .monitoredDirectories)
        }
    }

    public var sidebarSections: [SidebarSection] {
        didSet {
            store.save(sidebarSections, for: .sidebarSections)
        }
    }

    public var favoriteProjectPaths: [String] {
        didSet {
            store.save(favoriteProjectPaths, for: .favoriteProjectPaths)
        }
    }

    public var projectSortOrder: ProjectSortOrder {
        didSet {
            store.save(projectSortOrder, for: .projectSortOrder)
        }
    }

    public var recentProjectPaths: [String] {
        didSet {
            store.save(recentProjectPaths, for: .recentProjectPaths)
        }
    }

    public var gitClientPath: String {
        didSet {
            store.save(gitClientPath, for: .gitClientPath)
        }
    }

    public var hotkeyKeyCode: UInt32 {
        didSet {
            store.save(Int(hotkeyKeyCode), for: .hotkeyKeyCode)
        }
    }

    public var hotkeyModifiers: UInt32 {
        didSet {
            store.save(Int(hotkeyModifiers), for: .hotkeyModifiers)
        }
    }

    public var projectTags: [String: [String]] {
        didSet {
            store.save(projectTags, for: .projectTags)
        }
    }

    public var availableTags: [String] {
        didSet {
            store.save(availableTags, for: .availableTags)
        }
    }

    var collections: [ProjectCollection] {
        didSet {
            store.save(collections, for: .collections)
        }
    }

    func tags(for project: DiscoveredProject) -> [String] {
        projectTags[project.stablePath] ?? []
    }

    func setTags(_ tags: [String], for project: DiscoveredProject) {
        if tags.isEmpty {
            projectTags.removeValue(forKey: project.stablePath)
        } else {
            projectTags[project.stablePath] = tags
        }
    }

    func toggleTag(_ tag: String, for project: DiscoveredProject) {
        var tags = self.tags(for: project)
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
        setTags(tags, for: project)
    }

    public func renameTag(_ old: String, to new: String) {
        guard old != new else { return }
        if let index = availableTags.firstIndex(of: old) {
            availableTags[index] = new
        }
        for (path, tags) in projectTags {
            if tags.contains(old) {
                projectTags[path] = tags.map { $0 == old ? new : $0 }
            }
        }
    }

    public func deleteTag(_ name: String) {
        availableTags.removeAll { $0 == name }
        for (path, tags) in projectTags {
            let filtered = tags.filter { $0 != name }
            if filtered.isEmpty {
                projectTags.removeValue(forKey: path)
            } else if filtered.count != tags.count {
                projectTags[path] = filtered
            }
        }
    }

    /// Records a project path as the most recently viewed, keeping at most 10 entries.
    public func recordRecentProject(_ path: String) {
        var paths = recentProjectPaths
        paths.removeAll { $0 == path }
        paths.insert(path, at: 0)
        if paths.count > 10 {
            paths = Array(paths.prefix(10))
        }
        recentProjectPaths = paths
    }

    // MARK: Setup

    /// The key–value store that backs this settings container.
    @ObservationIgnored
    private let store: AnyKeyValueStore<AppSettings.Key>

    /// Creates a new instance of `AppSettings`.
    ///
    /// - Parameter store: The store used to persist values. If `nil`,
    ///   defaults to a `UserDefaults`-backed store.
    ///
    public init(store: AnyKeyValueStore<AppSettings.Key>? = nil) {
        self.store = store ?? .defaultStore
        colorScheme = self.store.load(.colorScheme, default: .system)
        
        monitoredDirectories = self.store.load(.monitoredDirectories, default: [])
        sidebarSections = self.store.load(.sidebarSections, default: [])
        favoriteProjectPaths = self.store.load(.favoriteProjectPaths, default: [])
        projectSortOrder = self.store.load(.projectSortOrder, default: .alphabetical)
        recentProjectPaths = self.store.load(.recentProjectPaths, default: [])
        gitClientPath = self.store.load(.gitClientPath, default: "/Applications/SourceTree.app/Contents/Resources/stree")
        // Defaults: § key (0x0A), Cmd+Shift (cmdKey 0x100 | shiftKey 0x200 = 0x300)
        hotkeyKeyCode = UInt32(self.store.load(.hotkeyKeyCode, default: 0x0A))
        hotkeyModifiers = UInt32(self.store.load(.hotkeyModifiers, default: 0x300))
        projectTags = self.store.load(.projectTags, default: [:])
        availableTags = self.store.load(.availableTags, default: [])
        collections = self.store.load(.collections, default: [])
    }
}
