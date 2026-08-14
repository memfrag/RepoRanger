# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepoRanger is a native macOS app (SwiftUI) that scans directories for Xcode projects, Swift packages, and git repositories, displaying them in a three-column NavigationSplitView with README preview. Built by Apparata AB.

## Build

`RepoRanger.xcodeproj` is checked into the repository and edited directly. There is no XcodeGen step — do not look for an `XcodeProject.yml`, and edit the project through Xcode or by modifying `project.pbxproj`.

Build from Xcode using the **RepoRanger (Debug)** or **RepoRanger (Release)** scheme, or from the command line:
```
xcodebuild -project RepoRanger.xcodeproj -scheme "RepoRanger (Debug)" build
```

**There is no linter in this project, by choice.** SwiftLint was removed deliberately — don't reintroduce it, and don't add `swiftlint:disable` comments. `xcodebuild` is the only automated check, so never describe a change as "lint clean"; say what actually ran.

Match the style of the surrounding code instead. Existing conventions worth preserving: `setUp`/`shutDown`/`logIn`/`logOut` rather than `setup`/`shutdown`/`login`/`logout`, and no `vc` as a variable name.

Release builds (archive, sign, notarize, package, publish): `./scripts/build-and-notarize.sh`. This is a single interactive pipeline that goes all the way to production — it prompts for a version number and release title, then bumps `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` in `project.pbxproj` via `sed`, commits and **pushes to origin/main**, archives and notarizes, creates and pushes a git tag, publishes a GitHub release with the DMG, and finally regenerates and pushes `appcast.xml`. That last step is what ships the update to existing users over Sparkle. There is no dry-run and no confirmation between steps, so inspect the build before starting the script, not during. It requires a keychain profile named `notary` and the `gh` CLI.

The project has a single target, `RepoRanger`, and no test targets.

## Key Architecture

- **Swift 6.2** with `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` — all types are MainActor-isolated by default.
- **macOS 26.0** deployment target, App Sandbox enabled.
- **Bundle ID prefix:** `io.apparata`

### AppEnvironment Pattern

`AppEnvironment` (in `RepoRanger/macOS/App Environment/`) is a centralized dependency container holding `AppSettings`, `AuthService`, and `EngineeringMode`. It has `.live()` and `.mock()` variants. The `.default` singleton selects mock when the `APP_ENVIRONMENT` env var equals "mock" in DEBUG builds. The `appEnvironment(_:)` view modifier injects all three into the SwiftUI environment.

### Settings

`AppSettings` is an `@Observable` class backed by `KeyValueStore` (UserDefaults). Keys: `colorScheme`, `monitoredDirectories`, `sidebarSections`, `favoriteProjectPaths`, `projectSortOrder`, `recentProjectPaths`, `gitClientPath`, `hotkeyKeyCode`, `hotkeyModifiers`, `projectTags`, `availableTags`, and `collections`. Mock variant uses an in-memory store.

### Directory Scanning

`DirectoryScanner` recursively enumerates a directory for `.xcodeproj` bundles, `Package.swift` files, and git repositories. It skips nested content under discovered Xcode projects and filters out sub-packages that live inside an Xcode project directory. Results are `DiscoveredProject` values with kind (`.xcodeProject` / `.swiftPackage` / `.gitRepository`), URL, and optional README URL.

A directory containing a `.git` entry is only reported as a `.gitRepository` if no Xcode project or Swift package was discovered anywhere inside it — so a repo built around an `.xcodeproj` still lists as an Xcode project. Nested repositories (submodules, vendored clones) are not listed separately from their outermost repo. `DiscoveredProject.directory` gives the containing directory for any kind, and `canOpenInXcode` is false for plain git repos.

`MonitoredDirectory` uses security-scoped bookmarks to persist sandbox access to user-selected folders.

### Code Organization

- `RepoRanger/All Platforms/` — Shared models, services, settings, auth, engineering mode (platform-agnostic)
- `RepoRanger/macOS/` — All macOS UI: main window, sidebar, panes, menu bar, settings, export
- `Packages/AppDesign/` — Local Swift package for design tokens (colors, typography, icons) with per-platform modules

### Dependencies

Remote packages are Swift Package Manager dependencies declared in the Xcode project itself (`XCRemoteSwiftPackageReference` entries in `project.pbxproj`) — there is no manifest file listing them. 19 are from the `apparata` GitHub org; the two exceptions are `soffes/HotKey` and `sparkle-project/Sparkle`. `Packages/AppDesign` is a local package referenced by path.
