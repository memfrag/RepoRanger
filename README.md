# RepoRanger

A macOS app for discovering and managing Xcode projects and Swift packages across your local directories.

## Overview

RepoRanger scans user-specified directories for Xcode projects (`.xcodeproj`) and Swift packages (`Package.swift`), presenting them in an organized three-column navigation interface. It provides quick access to README files, project metadata, and common actions like opening in Xcode or revealing in Finder.

## Features

- **Directory scanning** — Add monitored directories and automatically discover all Xcode projects and Swift packages within them.
- **README preview** — View rendered Markdown README files directly in the detail pane.
- **Project metadata** — Displays Swift tools version, deployment targets, and git status (uncommitted changes) as metadata pills.
- **Favorites** — Mark projects as favorites for quick access from the menu bar.
- **Menu bar** — A menu bar extra provides one-click access to favorite projects, opening them directly in Xcode.
- **Sorting & filtering** — Sort projects alphabetically or by recently changed, and filter by name.
- **Quick actions** — Open in Xcode, reveal in Finder, open in SourceTree, browse on GitHub, or copy the project path.
- **Navigation history** — Back/forward navigation between viewed projects.
- **Sidebar sections** — Organize monitored directories into custom named sections.
- **Always on top** — Optionally pin the window above other windows.

## Requirements

- macOS 26.0+
- Swift 6.2
- Xcode 26+

## Building

Open `RepoRanger.xcodeproj` in Xcode and build using either the Debug or Release scheme.

### Build, Notarize, and Package

The `scripts/build-and-notarize.sh` script handles the full release pipeline:

1. Archives the app using the Release scheme (arm64, hardened runtime)
2. Exports the archive using `scripts/ExportOptions.plist`
3. Verifies the code signature
4. Submits the app to Apple's notary service and waits for approval
5. Staples the notarization ticket to the app
6. Packages the result as a versioned `.zip` file in `build/`

```
./scripts/build-and-notarize.sh
```

The script expects a keychain profile named `notary` for notarization credentials. Set it up with:

```
xcrun notarytool store-credentials notary --apple-id <APPLE_ID> --team-id <TEAM_ID>
```

## Project Structure

```
RepoRanger/
  All Platforms/       Shared models, services, settings, and infrastructure
    Models/            DiscoveredProject, MonitoredDirectory, ProjectMetadata, etc.
    Services/          DirectoryScanner, ProjectMetadataExtractor
    Infrastructure/    Settings, auth, engineering mode
  macOS/               macOS-specific UI
    Main Window/       Main three-column NavigationSplitView
    Sidebar/           Directory list and project list sidebar
    Panes/             README detail view, project list, empty state
    Menu Bar Button/   Menu bar extra with favorites popup
    Settings/          Preferences window
    Export/            File export support
Packages/
  AppDesign/           Local Swift package for design tokens (colors, typography, icons)
```
