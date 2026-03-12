# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepoRanger is a native macOS app (SwiftUI) that scans directories for Xcode projects and Swift packages, displaying them in a three-column NavigationSplitView with README preview. Built by Apparata AB.

## Build & Lint

The Xcode project is generated from `XcodeProject.yml` using XcodeGen:
```
xcodegen generate
```

Build from Xcode using the **RepoRanger (Debug)** or **RepoRanger (Release)** scheme, or from the command line:
```
xcodebuild -project RepoRanger.xcodeproj -scheme "RepoRanger (Debug)" build
```

SwiftLint runs automatically as a post-compile build phase via Mint (pinned in `Mintfile` to `realm/SwiftLint@0.49.1`). The config is in `.swiftlint.yml` and uses an `only_rules` whitelist with 54 rules. Notable custom rules enforce `setUp`/`shutDown`/`logIn`/`logOut` naming (not `setup`/`shutdown`/`login`/`logout`) and discourage using `vc` as a variable name.

Release builds (archive, sign, notarize, package): `./scripts/build-and-notarize.sh`

There are no test targets in this project.

## Key Architecture

- **Swift 6.2** with `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` — all types are MainActor-isolated by default.
- **macOS 26.0** deployment target, App Sandbox enabled.
- **Bundle ID prefix:** `io.apparata`

### AppEnvironment Pattern

`AppEnvironment` (in `RepoRanger/macOS/App Environment/`) is a centralized dependency container holding `AppSettings`, `AuthService`, and `EngineeringMode`. It has `.live()` and `.mock()` variants. The `.default` singleton selects mock when the `APP_ENVIRONMENT` env var equals "mock" in DEBUG builds. The `appEnvironment(_:)` view modifier injects all three into the SwiftUI environment.

### Settings

`AppSettings` is an `@Observable` class backed by `KeyValueStore` (UserDefaults). Keys: `colorScheme`, `monitoredDirectories`, `sidebarSections`, `favoriteProjectPaths`, `projectSortOrder`. Mock variant uses an in-memory store.

### Directory Scanning

`DirectoryScanner` recursively enumerates a directory for `.xcodeproj` bundles and `Package.swift` files. It skips nested content under discovered Xcode projects and filters out sub-packages that live inside an Xcode project directory. Results are `DiscoveredProject` values with kind (`.xcodeProject` / `.swiftPackage`), URL, and optional README URL.

`MonitoredDirectory` uses security-scoped bookmarks to persist sandbox access to user-selected folders.

### Code Organization

- `RepoRanger/All Platforms/` — Shared models, services, settings, auth, engineering mode (platform-agnostic)
- `RepoRanger/macOS/` — All macOS UI: main window, sidebar, panes, menu bar, settings, export
- `Packages/AppDesign/` — Local Swift package for design tokens (colors, typography, icons) with per-platform modules

### Dependencies

All remote packages are from the `apparata` GitHub org. See `XcodeProject.yml` for the full list with pinned versions.
