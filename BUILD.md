## Requirements

- macOS 26.0+
- Swift 6.2
- Xcode 26+

## Building

`RepoRanger.xcodeproj` is checked into the repository — there is no generation step. Open it in Xcode and build using either the Debug or Release scheme, or build from the command line:

```
xcodebuild -project RepoRanger.xcodeproj -scheme "RepoRanger (Debug)" build
```

There is no linter and there are no test targets, so the compile is the only automated check.

### Build, Notarize, and Release

The `scripts/build-and-notarize.sh` script is the full release pipeline. It does not stop at a local artifact — it publishes, and it pushes to `main` three times along the way:

1. Compares the project's `MARKETING_VERSION` against the latest GitHub release. If it is not newer, prompts for a new version, rewrites `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`, then commits `Version <x.y.z>` and **pushes to origin/main**
2. Archives the app using the Release scheme (arm64, hardened runtime)
3. Exports the archive using `scripts/ExportOptions.plist`
4. Verifies the code signature
5. Packages the app as a versioned `.dmg` in `build/`
6. Submits the DMG to Apple's notary service and waits for approval
7. Staples the notarization ticket to the DMG
8. Signs the DMG with Sparkle's `sign_update` (EdDSA)
9. Prompts for a release title, then **creates and pushes the git tag** and publishes a **GitHub release** with the DMG attached
10. Regenerates `appcast.xml`, commits `Update appcast for <x.y.z>`, and **pushes to origin/main**

```
./scripts/build-and-notarize.sh
```

Step 10 is what actually ships the update — once `appcast.xml` is on `main`, existing installs are offered the new version by Sparkle on their next check. There is no dry-run mode, no staging step, and no confirmation between steps: the only two pauses are the version and release-title prompts, both of which come before anything is published. Inspect the build before starting the script, not during.

The script expects the `gh` CLI to be authenticated, and a keychain profile named `notary` for notarization credentials. Set the latter up with:

```
xcrun notarytool store-credentials notary --apple-id <APPLE_ID> --team-id <TEAM_ID>
```

Sparkle's signing tools are downloaded into `Sparkle-tools/` on first run. Build artifacts land in `build/`, which is wiped at the start of every run.

## Project Structure

```
RepoRanger/
  All Platforms/       Shared, platform-agnostic code
    Models/            DiscoveredProject, MonitoredDirectory, ProjectCollection, etc.
    Services/          DirectoryScanner, ProjectMetadataExtractor, LicenseDetector
    Infrastructure/    Settings, auth, engineering mode
    App Information/   Version and open source attributions
    Utilities/         Shared helpers
  macOS/               macOS-specific UI
    App Environment/   Dependency container (live and mock variants)
    Main Window/       Main three-column NavigationSplitView
    Sidebar/           Directory list, collections, favorites
    Panes/             Project list, README detail view, empty state
    Menu Bar Button/   Menu bar extra with favorites popup
    Command K Bar/     Fuzzy project switcher overlay
    Settings/          Preferences window
    Help Window/       Help window and menu commands
    Updates/           Sparkle check-for-updates command
    My Menu Commands/  Menu bar commands
    Utilities/         AppKit and Bundle extensions
Packages/
  AppDesign/           Local Swift package for design tokens (colors, typography, icons)
scripts/
  build-and-notarize.sh  Full release pipeline
  ExportOptions.plist    Archive export configuration
```
