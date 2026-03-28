# RepoRanger

A macOS app for discovering and managing Xcode projects and Swift packages across your local directories.

## Overview

RepoRanger scans user-specified directories for Xcode projects (`.xcodeproj`) and Swift packages (`Package.swift`), presenting them in an organized three-column navigation interface. It provides quick access to README files, project metadata, and common a
ctions like opening in Xcode or revealing in Finder.

<img width="2348" height="1798" alt="RepoRanger" src="https://github.com/user-attachments/assets/8c16a214-a4d2-4b23-aa2e-85ba8a34633f" />

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

## License

RepoRanger is released under the [BSD Zero Clause License](LICENSE) (0BSD).
