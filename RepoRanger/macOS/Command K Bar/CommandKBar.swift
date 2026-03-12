//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

private struct IndexedProject: Identifiable {
    var id: UUID { project.id }
    var index: Int
    var project: DiscoveredProject
}

struct CommandKBar: View {

    let projects: [DiscoveredProject]
    @Binding var isPresented: Bool
    var onSelect: (DiscoveredProject) -> Void

    @Environment(AppSettings.self) private var settings
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFieldFocused: Bool

    private var filteredProjects: [IndexedProject] {
        let sorted: [DiscoveredProject]

        if searchText.isEmpty {
            let recentPaths = settings.recentProjectPaths
            let projectsByPath = Dictionary(
                projects.map { ($0.stablePath, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            sorted = recentPaths.compactMap { projectsByPath[$0] }
        } else {
            sorted = projects
                .compactMap { project -> (DiscoveredProject, Int, Int)? in
                    let nameScore = fuzzyMatch(pattern: searchText, text: project.name)
                    let parentScore = fuzzyMatch(pattern: searchText, text: project.parentName)
                    guard nameScore != nil || parentScore != nil else {
                        return nil
                    }
                    // Name match is primary; parent match is secondary tiebreaker.
                    // Use Int.max as sentinel for no match so it sorts last.
                    return (project, nameScore ?? .max, parentScore ?? .max)
                }
                .sorted {
                    if $0.1 != $1.1 { return $0.1 < $1.1 }
                    if $0.2 != $1.2 { return $0.2 < $1.2 }
                    return $0.0.name.localizedCompare($1.0.name) == .orderedAscending
                }
                .map(\.0)
        }

        return Array(
            sorted
                .prefix(10)
                .enumerated()
                .map { IndexedProject(index: $0.offset, project: $0.element) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Quick Find…", text: $searchText.animation())
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFieldFocused)
                    .autocorrectionDisabled()
                    .textContentType(.none)
                    .onSubmit {
                        // Fallback for plain Return without modifiers
                        openSelected()
                    }

            }
            .padding(12)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredProjects) { indexedProject in
                            let index = indexedProject.index
                            let project = indexedProject.project

                            resultRow(project, isSelected: index == selectedIndex)
                                .simultaneousGesture(TapGesture().modifiers(.command).onEnded {
                                    selectedIndex = index
                                    revealSelectedInFinder()
                                })
                                .simultaneousGesture(TapGesture().modifiers(.option).onEnded {
                                    selectedIndex = index
                                    openSelectedInXcode()
                                })
                                .onTapGesture {
                                    selectedIndex = index
                                    openSelected()
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 340)
                .scrollIndicators(.hidden)
                .onChange(of: selectedIndex) {
                    guard filteredProjects.indices.contains(selectedIndex) else { return }
                    proxy.scrollTo(filteredProjects[selectedIndex].id)
                }
                .onChange(of: searchText) {
                    clampSelectedIndex()
                }
            }

            if !filteredProjects.isEmpty {
                Divider()

                HStack(spacing: 12) {
                    shortcutHint("⌘⏎", "Reveal in Finder")
                    shortcutHint("⌥⏎", "Open in Xcode")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .focusEffectDisabled()
        .onAppear {
            searchText = ""
            selectedIndex = 0

            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredProjects.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return, phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                revealSelectedInFinder()
                return .handled
            } else if keyPress.modifiers.contains(.option) {
                openSelectedInXcode()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private func resultRow(_ project: DiscoveredProject, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            projectIcon(for: project)

            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .lineLimit(1)

                Text(project.parentName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(project.kind.displayName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : .clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private func shortcutHint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .tracking(2)
                .font(.caption.monospaced())
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))

            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private func projectIcon(for project: DiscoveredProject) -> some View {
        switch project.kind {
        case .xcodeProject:
            Image(systemName: "hammer.fill")
                .font(.system(size: 7))
                .foregroundStyle(.black)
                .frame(width: 14, height: 14)
                .offset(x: 0.5, y: -0.5)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.blue)
                )

        case .swiftPackage:
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(project.iconColor)
        }
    }

    private func clampSelectedIndex() {
        if filteredProjects.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, filteredProjects.count - 1)
        }
    }

    private func openSelected() {
        guard filteredProjects.indices.contains(selectedIndex) else { return }
        let project = filteredProjects[selectedIndex].project
        settings.recordRecentProject(project.stablePath)
        onSelect(project)
        isPresented = false
    }

    private func revealSelectedInFinder() {
        guard filteredProjects.indices.contains(selectedIndex) else { return }
        let project = filteredProjects[selectedIndex].project
        settings.recordRecentProject(project.stablePath)
        NSWorkspace.shared.activateFileViewerSelecting([project.url])
        isPresented = false
    }

    private func openSelectedInXcode() {
        guard filteredProjects.indices.contains(selectedIndex) else { return }
        let project = filteredProjects[selectedIndex].project
        settings.recordRecentProject(project.stablePath)
        project.openInXcode()
        isPresented = false
    }
}
