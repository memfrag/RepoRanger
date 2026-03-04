//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct DirectoryListView: View {

    @Bindable var settings: AppSettings
    @Binding var selection: MonitoredDirectory?
    var projectCounts: [UUID: Int]
    var addSection: () -> Void

    @State private var renamingSection: SidebarSection?
    @State private var renameText: String = ""

    var body: some View {
        List(selection: $selection) {
            ForEach(settings.sidebarSections) { section in
                sectionView(for: section)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .alert("Rename Section", isPresented: .init(
            get: { renamingSection != nil },
            set: { if !$0 { renamingSection = nil } }
        )) {
            TextField("Section Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingSection = nil }
            Button("Rename") {
                if let section = renamingSection,
                   let index = settings.sidebarSections.firstIndex(where: { $0.id == section.id }) {
                    var updatedSections = settings.sidebarSections
                    updatedSections[index].name = renameText
                    settings.sidebarSections = updatedSections
                }
                renamingSection = nil
            }
        }
    }

    @ViewBuilder
    private func sectionView(for section: SidebarSection) -> some View {
        Section {
            ForEach(directoriesIn(section)) { directory in
                HStack {
                    Label {
                        Text(directory.displayName)
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    if let count = projectCounts[directory.id], count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(directory)
                    .contextMenu {
                        Button("Reveal in Finder") {
                            if let url = directory.resolveURL() {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path(percentEncoded: false))
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        if settings.sidebarSections.count > 1 {
                            Menu("Move to") {
                                ForEach(settings.sidebarSections.filter { $0.id != section.id }) { targetSection in
                                    Button(targetSection.name) {
                                        moveDirectory(directory, from: section, to: targetSection)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button("Remove", role: .destructive) {
                            withAnimation {
                                removeDirectory(directory, from: section)
                            }
                        }
                    }
            }
            .onMove { source, destination in
                moveDirectories(in: section, from: source, to: destination)
            }

        } header: {
            HStack {
                Text(section.name)
                Spacer()
                Button {
                    addDirectory(to: section)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 6)
            }
            .contextMenu {
                Button("Add Directory") {
                    addDirectory(to: section)
                }
                Divider()
                Button("Rename Section") {
                    renameText = section.name
                    renamingSection = section
                }
                Divider()
                Button("Delete Section", role: .destructive) {
                    withAnimation {
                        deleteSection(section)
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Menu {
                Button("Add Section") {
                    addSection()
                }
            } label: {
                Image(systemName: "plus")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            Spacer()
        }
        .padding(8)
    }

    // MARK: - Helpers

    private func addDirectory(to section: SidebarSection) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory to monitor for projects"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let directory = try? MonitoredDirectory(url: url) else { return }

        guard !settings.monitoredDirectories.contains(where: { $0.path == directory.path }) else { return }

        guard let sectionIndex = settings.sidebarSections.firstIndex(where: { $0.id == section.id }) else { return }

        settings.monitoredDirectories.append(directory)
        var updatedSections = settings.sidebarSections
        updatedSections[sectionIndex].directoryIDs.append(directory.id)
        settings.sidebarSections = updatedSections
        selection = directory
    }

    private func directoriesIn(_ section: SidebarSection) -> [MonitoredDirectory] {
        section.directoryIDs.compactMap { id in
            settings.monitoredDirectories.first(where: { $0.id == id })
        }
    }

    private func moveDirectory(_ directory: MonitoredDirectory, from source: SidebarSection, to target: SidebarSection) {
        guard let sourceIndex = settings.sidebarSections.firstIndex(where: { $0.id == source.id }),
              let targetIndex = settings.sidebarSections.firstIndex(where: { $0.id == target.id }) else { return }
        withAnimation {
            var updatedSections = settings.sidebarSections
            updatedSections[sourceIndex].directoryIDs.removeAll { $0 == directory.id }
            updatedSections[targetIndex].directoryIDs.append(directory.id)
            settings.sidebarSections = updatedSections
        }
    }

    private func removeDirectory(_ directory: MonitoredDirectory, from section: SidebarSection) {
        guard let sectionIndex = settings.sidebarSections.firstIndex(where: { $0.id == section.id }) else { return }
        var updatedSections = settings.sidebarSections
        updatedSections[sectionIndex].directoryIDs.removeAll { $0 == directory.id }
        settings.sidebarSections = updatedSections
        settings.monitoredDirectories.removeAll { $0.id == directory.id }
        if selection?.id == directory.id {
            selection = nil
        }
    }

    private func moveDirectories(in section: SidebarSection, from source: IndexSet, to destination: Int) {
        guard let sectionIndex = settings.sidebarSections.firstIndex(where: { $0.id == section.id }) else { return }
        var updatedSections = settings.sidebarSections
        updatedSections[sectionIndex].directoryIDs.move(fromOffsets: source, toOffset: destination)
        settings.sidebarSections = updatedSections
    }

    private func deleteSection(_ section: SidebarSection) {
        let directoryIDsToRemove = Set(section.directoryIDs)
        settings.monitoredDirectories.removeAll { directoryIDsToRemove.contains($0.id) }
        if let selected = selection, directoryIDsToRemove.contains(selected.id) {
            selection = nil
        }
        var updatedSections = settings.sidebarSections
        updatedSections.removeAll { $0.id == section.id }
        settings.sidebarSections = updatedSections
    }
}
