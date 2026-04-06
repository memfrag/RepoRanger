//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct Sidebar: View {

    @Environment(AppSettings.self) private var settings

    @State private var sidebarSelection: SidebarSelection?
    @State private var selectedProject: DiscoveredProject?
    @State private var projectsByDirectory: [UUID: [DiscoveredProject]] = [:]
    @State private var isScanning: Bool = false
    @State private var accessedURLs: [URL] = []

    @State private var history: [DiscoveredProject] = []
    @State private var historyIndex: Int = -1
    @State private var isNavigating = false

    @State private var isCommandKBarPresented = false

    @State private var isAddingSectionAlertPresented = false
    @State private var newSectionName = ""

    var body: some View {
        NavigationSplitView {
            DirectoryListView(
                settings: settings,
                selection: $sidebarSelection,
                selectedProject: $selectedProject,
                allProjects: allProjects,
                projectsByDirectory: projectsByDirectory,
                addSection: { isAddingSectionAlertPresented = true }
            )
            .navigationTitle("Directories")
            .frame(minWidth: 200, idealWidth: 200, maxWidth: 300)
            .alert("New Section", isPresented: $isAddingSectionAlertPresented) {
                TextField("Section Name", text: $newSectionName)
                Button("Cancel", role: .cancel) { newSectionName = "" }
                Button("Add") {
                    addSection(name: newSectionName)
                    newSectionName = ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await scanAllDirectories() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(settings.monitoredDirectories.isEmpty || isScanning)
                }
            }
        } content: {
            ProjectListView(
                settings: settings,
                projects: selectedProjects,
                isScanning: isScanning,
                selection: $selectedProject
            )
            .navigationTitle(selectedTitle)
            .frame(minWidth: 200, idealWidth: 250)
        } detail: {
            if let selectedProject {
                ReadmeDetailView(settings: settings, project: selectedProject)
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            HStack(spacing: 0) {
                                Button {
                                    goBack()
                                } label: {
                                    Label("Back", systemImage: "chevron.left")
                                }
                                .disabled(!canGoBack)
                                Button {
                                    goForward()
                                } label: {
                                    Label("Forward", systemImage: "chevron.right")
                                }
                                .disabled(!canGoForward)
                            }
                        }
                    }
            } else {
                EmptyPane()
            }
        }
        .focusedSceneValue(\.commandKBarToggle, $isCommandKBarPresented)
        .overlay {
            if isCommandKBarPresented {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isCommandKBarPresented = false
                        }
                    VStack {
                        CommandKBar(
                            projects: allProjects,
                            isPresented: $isCommandKBarPresented,
                            onSelect: { selectProject($0) }
                        )
                        .padding(.top, 80)
                        Spacer()
                    }
                }
                .transition(.identity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCommandKBar)) { _ in
            isCommandKBarPresented = true
        }
        .onChange(of: selectedProject) {
            guard !isNavigating else { return }
            guard let project = selectedProject else { return }
            settings.recordRecentProject(project.stablePath)
            if historyIndex >= 0, historyIndex < history.count,
               history[historyIndex].stablePath == project.stablePath {
                return
            }
            history.removeSubrange((historyIndex + 1)...)
            history.append(project)
            historyIndex = history.count - 1
        }
        .onChange(of: sidebarSelection) {
            // Don't clear if the selected project belongs to the new selection
            if let project = selectedProject {
                let projects = selectedProjects
                if projects.contains(where: { $0.stablePath == project.stablePath }) {
                    return
                }
            }
            selectedProject = nil
        }
        .onChange(of: settings.monitoredDirectories) {
            selectedProject = nil
            Task { await scanAllDirectories() }
        }
        .task {
            await scanAllDirectories()
        }
    }

    private func addSection(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            settings.sidebarSections.append(SidebarSection(name: trimmed))
        }
    }

    private func stopAccessingAll() {
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessedURLs = []
    }

    private var canGoBack: Bool {
        historyIndex > 0
    }

    private var canGoForward: Bool {
        historyIndex < history.count - 1
    }

    private func goBack() {
        guard canGoBack else { return }
        isNavigating = true
        historyIndex -= 1
        selectedProject = history[historyIndex]
        isNavigating = false
    }

    private func goForward() {
        guard canGoForward else { return }
        isNavigating = true
        historyIndex += 1
        selectedProject = history[historyIndex]
        isNavigating = false
    }

    private func selectProject(_ project: DiscoveredProject) {
        if let (directoryID, _) = projectsByDirectory.first(where: {
            $0.value.contains(where: { $0.stablePath == project.stablePath })
        }) {
            if let dir = settings.monitoredDirectories.first(where: { $0.id == directoryID }) {
                sidebarSelection = .directory(dir)
            }
        }
        selectedProject = project
    }

    private var allProjects: [DiscoveredProject] {
        projectsByDirectory.values.flatMap { $0 }
    }

    private var selectedDirectory: MonitoredDirectory? {
        if case .directory(let dir) = sidebarSelection { return dir }
        return nil
    }

    private var selectedTitle: String {
        switch sidebarSelection {
        case .directory(let dir): dir.displayName
        case .recentCollection: "Recent"
        case .customCollection(let col): col.name
        case nil: "Projects"
        }
    }

    private var selectedProjects: [DiscoveredProject] {
        switch sidebarSelection {
        case .directory(let dir):
            return projectsByDirectory[dir.id] ?? []
        case .recentCollection:
            return recentProjects
        case .customCollection(let collection):
            return filteredProjects(for: collection)
        case nil:
            return []
        }
    }

    private var recentProjects: [DiscoveredProject] {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? .distantPast
        return allProjects
            .compactMap { project -> (DiscoveredProject, Date)? in
                guard let date = lastModifiedDate(for: project), date >= sixMonthsAgo else { return nil }
                return (project, date)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    private func filteredProjects(for collection: ProjectCollection) -> [DiscoveredProject] {
        var projects = allProjects

        // Filter by directory
        if let dirID = collection.directoryID {
            projects = projectsByDirectory[dirID] ?? []
        }

        // Filter by kind
        switch collection.kindFilter {
        case .all: break
        case .xcodeOnly: projects = projects.filter { $0.kind == .xcodeProject }
        case .swiftPackageOnly: projects = projects.filter { $0.kind == .swiftPackage }
        }

        // Filter by tags (AND logic)
        if !collection.tagFilters.isEmpty {
            projects = projects.filter { project in
                let projectTags = Set(settings.tags(for: project))
                return Set(collection.tagFilters).isSubset(of: projectTags)
            }
        }

        // Filter by time limit
        if let cutoff = collection.timeLimit.cutoffDate {
            projects = projects.filter { project in
                guard let date = lastModifiedDate(for: project) else { return false }
                return date >= cutoff
            }
        }

        // Filter by README
        switch collection.readmeFilter {
        case .any: break
        case .yes: projects = projects.filter { $0.readmeURL != nil }
        case .no: projects = projects.filter { $0.readmeURL == nil }
        }

        // Filter by git repo
        switch collection.gitRepoFilter {
        case .any: break
        case .yes: projects = projects.filter { $0.isGitRepo }
        case .no: projects = projects.filter { !$0.isGitRepo }
        }

        // Sort
        switch collection.sortOrder {
        case .alphabetical:
            return projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recentlyChanged:
            return projects.sorted { a, b in
                (lastModifiedDate(for: a) ?? .distantPast) > (lastModifiedDate(for: b) ?? .distantPast)
            }
        }
    }

    private func lastModifiedDate(for project: DiscoveredProject) -> Date? {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        return try? FileManager.default
            .attributesOfItem(atPath: directory.path(percentEncoded: false))[.modificationDate] as? Date
    }

    private func scanAllDirectories() async {
        stopAccessingAll()
        isScanning = true

        var results: [UUID: [DiscoveredProject]] = [:]
        for directory in settings.monitoredDirectories {
            guard let url = directory.resolveURL() else { continue }
            accessedURLs.append(url)
            let projects = await DirectoryScanner.scan(directory: url)
            results[directory.id] = projects
        }

        projectsByDirectory = results
        isScanning = false
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
