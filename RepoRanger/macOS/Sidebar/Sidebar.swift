//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct Sidebar: View {

    @State private var settings = AppSettings()

    @State private var selectedDirectory: MonitoredDirectory?
    @State private var selectedProject: DiscoveredProject?
    @State private var projectsByDirectory: [UUID: [DiscoveredProject]] = [:]
    @State private var isScanning: Bool = false
    @State private var accessedURLs: [URL] = []

    @State private var isAddingSectionAlertPresented = false
    @State private var newSectionName = ""

    var body: some View {
        NavigationSplitView {
            DirectoryListView(
                settings: settings,
                selection: $selectedDirectory,
                projectCounts: projectsByDirectory.mapValues(\.count),
                addSection: { isAddingSectionAlertPresented = true }
            )
            .navigationTitle("Directories")
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 300)
            .alert("New Section", isPresented: $isAddingSectionAlertPresented) {
                TextField("Section Name", text: $newSectionName)
                Button("Cancel", role: .cancel) { newSectionName = "" }
                Button("Add") {
                    addSection(name: newSectionName)
                    newSectionName = ""
                }
            }
        } content: {
            ProjectListView(
                projects: selectedDirectoryProjects,
                isScanning: isScanning,
                selection: $selectedProject
            )
            .navigationTitle(selectedDirectory?.displayName ?? "Projects")
            .frame(minWidth: 200, idealWidth: 250)
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
        } detail: {
            if let selectedProject {
                ReadmeDetailView(project: selectedProject)
            } else {
                EmptyPane()
            }
        }
        .onChange(of: selectedDirectory) {
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
