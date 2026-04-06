//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct DirectoryListView: View {

    @Bindable var settings: AppSettings
    @Binding var selection: SidebarSelection?
    @Binding var selectedProject: DiscoveredProject?
    var allProjects: [DiscoveredProject]
    var projectsByDirectory: [UUID: [DiscoveredProject]]
    var addSection: () -> Void

    @State private var renamingSection: SidebarSection?
    @State private var renameText: String = ""
    @State private var editingCollection: ProjectCollection?
    @State private var isShowingCollectionForm = false

    var body: some View {
        List(selection: $selection) {
            favoritesSection

            ForEach(settings.sidebarSections) { section in
                sectionView(for: section)
            }

            collectionsSection
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
        .sheet(isPresented: $isShowingCollectionForm) {
            CollectionFormView(
                settings: settings,
                collection: editingCollection,
                onSave: { collection in
                    if let index = settings.collections.firstIndex(where: { $0.id == collection.id }) {
                        settings.collections[index] = collection
                    } else {
                        settings.collections.append(collection)
                    }
                    editingCollection = nil
                    isShowingCollectionForm = false
                },
                onCancel: {
                    editingCollection = nil
                    isShowingCollectionForm = false
                }
            )
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
                            .foregroundStyle(selection == .directory(directory) ? .white : .blue)
                    }
                    Spacer()
                    if let count = projectsByDirectory[directory.id]?.count, count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(SidebarSelection.directory(directory))
                    .contextMenu {
                        Button("Reveal in Finder", systemImage: "folder") {
                            if let url = directory.resolveURL() {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path(percentEncoded: false))
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        if settings.sidebarSections.count > 1 {
                            Menu("Move to") {
                                ForEach(settings.sidebarSections.filter { $0.id != section.id }) { targetSection in
                                    Button(targetSection.name, systemImage: "folder") {
                                        moveDirectory(directory, from: section, to: targetSection)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button("Remove", systemImage: "trash", role: .destructive) {
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
                Button("Add Directory", systemImage: "plus") {
                    addDirectory(to: section)
                }
                Divider()
                Button("Rename Section", systemImage: "pencil") {
                    renameText = section.name
                    renamingSection = section
                }
                Divider()
                Button("Delete Section", systemImage: "trash", role: .destructive) {
                    withAnimation {
                        deleteSection(section)
                    }
                }
            }
        }
    }

    private var favoriteProjects: [DiscoveredProject] {
        settings.favoriteProjectPaths.compactMap { path in
            allProjects.first { $0.stablePath == path }
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
        Section("Favorites") {
            if favoriteProjects.isEmpty {
                Text("No Favorites")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(favoriteProjects) { project in
                    favoriteRow(project)
                }
            }
        }
    }

    @ViewBuilder
    private func favoriteIcon(for project: DiscoveredProject) -> some View {
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

    private func favoriteRow(_ project: DiscoveredProject) -> some View {
        Button {
            selectFavorite(project)
        } label: {
            HStack(spacing: 6) {
                favoriteIcon(for: project)
                Text(project.name)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .draggable(project.stablePath)
        .dropDestination(for: String.self) { items, _ in
            guard let draggedPath = items.first,
                  let fromIndex = settings.favoriteProjectPaths.firstIndex(of: draggedPath),
                  let toIndex = settings.favoriteProjectPaths.firstIndex(of: project.stablePath),
                  fromIndex != toIndex else { return false }
            withAnimation {
                settings.favoriteProjectPaths.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
            return true
        }
        .contextMenu {
            let index = settings.favoriteProjectPaths.firstIndex(of: project.stablePath)
            Button("Move Up", systemImage: "arrow.up") {
                if let i = index, i > 0 {
                    settings.favoriteProjectPaths.swapAt(i, i - 1)
                }
            }
            .disabled(index == settings.favoriteProjectPaths.startIndex)
            Button("Move Down", systemImage: "arrow.down") {
                if let i = index, i < settings.favoriteProjectPaths.count - 1 {
                    settings.favoriteProjectPaths.swapAt(i, i + 1)
                }
            }
            .disabled(index == settings.favoriteProjectPaths.count - 1)
            Divider()
            Button("Remove from Favorites", systemImage: "star.slash") {
                settings.favoriteProjectPaths.removeAll { $0 == project.stablePath }
            }
            Divider()
            Button("Reveal in Finder", systemImage: "folder") {
                let directory = switch project.kind {
                case .xcodeProject: project.url.deletingLastPathComponent()
                case .swiftPackage: project.url
                }
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path(percentEncoded: false))
            }
            Button("Open in Xcode", systemImage: "hammer") {
                project.openInXcode()
            }
        }
    }

    private func selectFavorite(_ project: DiscoveredProject) {
        // Find the directory that contains this project
        if let (directoryID, _) = projectsByDirectory.first(where: { $0.value.contains(where: { $0.stablePath == project.stablePath }) }) {
            if let directory = settings.monitoredDirectories.first(where: { $0.id == directoryID }) {
                selection = .directory(directory)
            }
        }
        selectedProject = project
    }

    @ViewBuilder
    private var collectionsSection: some View {
        Section {
            Label("Recent", systemImage: "clock")
                .tag(SidebarSelection.recentCollection)
            ForEach(settings.collections) { collection in
                Label(collection.name, systemImage: "line.3.horizontal.decrease.circle")
                    .tag(SidebarSelection.customCollection(collection))
                    .contextMenu {
                        Button("Edit…", systemImage: "pencil") {
                            editingCollection = collection
                            isShowingCollectionForm = true
                        }
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                settings.collections.removeAll { $0.id == collection.id }
                                if selection == .customCollection(collection) {
                                    selection = nil
                                }
                            }
                        }
                    }
            }
        } header: {
            HStack {
                Text("Collections")
                Spacer()
                Button {
                    editingCollection = nil
                    isShowingCollectionForm = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 6)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Menu {
                Button("Add Section", systemImage: "plus") {
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
        selection = .directory(directory)
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
        if selection == .directory(directory) {
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
        if case .directory(let dir) = selection, directoryIDsToRemove.contains(dir.id) {
            selection = nil
        }
        var updatedSections = settings.sidebarSections
        updatedSections.removeAll { $0.id == section.id }
        settings.sidebarSections = updatedSections
    }
}
