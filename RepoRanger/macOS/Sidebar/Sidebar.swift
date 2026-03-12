//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct Sidebar: View {

    @Environment(AppSettings.self) private var settings

    @State private var selectedDirectory: MonitoredDirectory?
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
                selection: $selectedDirectory,
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
                projects: selectedDirectoryProjects,
                isScanning: isScanning,
                selection: $selectedProject
            )
            .navigationTitle(selectedDirectory?.displayName ?? "Projects")
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
        .onChange(of: selectedProject) {
            guard !isNavigating else { return }
            guard let project = selectedProject else { return }
            if historyIndex >= 0, historyIndex < history.count,
               history[historyIndex].stablePath == project.stablePath {
                return
            }
            history.removeSubrange((historyIndex + 1)...)
            history.append(project)
            historyIndex = history.count - 1
        }
        .onChange(of: selectedDirectory) {
            // Don't clear if the selected project belongs to the newly selected directory
            if let project = selectedProject,
               let dirID = selectedDirectory?.id,
               let projects = projectsByDirectory[dirID],
               projects.contains(where: { $0.stablePath == project.stablePath }) {
                return
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
            selectedDirectory = settings.monitoredDirectories.first { $0.id == directoryID }
        }
        selectedProject = project
    }

    private var allProjects: [DiscoveredProject] {
        projectsByDirectory.values.flatMap { $0 }
    }

    private var selectedDirectoryProjects: [DiscoveredProject] {
        guard let id = selectedDirectory?.id else { return [] }
        return projectsByDirectory[id] ?? []
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
