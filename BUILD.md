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
Packages/
  AppDesign/           Local Swift package for design tokens (colors, typography, icons)
```
