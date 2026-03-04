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
    }
}
