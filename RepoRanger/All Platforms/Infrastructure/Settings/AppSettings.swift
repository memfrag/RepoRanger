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
    }
}
