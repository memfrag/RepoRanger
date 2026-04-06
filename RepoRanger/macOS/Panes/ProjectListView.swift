//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ProjectListView: View {

    @Bindable var settings: AppSettings
    let projects: [DiscoveredProject]
    let isScanning: Bool
    @Binding var selection: DiscoveredProject?

    @State private var isXcodeProjectsExpanded = true
    @State private var isSwiftPackagesExpanded = true
    @State private var searchText = ""
    @State private var activeTagFilters: Set<String> = []
    @State private var isShowingNewTagAlert = false
    @State private var newTagName = ""
    @State private var newTagTargetProject: DiscoveredProject?

    private var filteredProjects: [DiscoveredProject] {
        var base = searchText.isEmpty ? projects : projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        if !activeTagFilters.isEmpty {
            base = base.filter { project in
                let projectTags = Set(settings.tags(for: project))
                return activeTagFilters.isSubset(of: projectTags)
            }
        }
        switch settings.projectSortOrder {
        case .alphabetical:
            return base
        case .recentlyChanged:
            return base.sorted { a, b in
                (lastModifiedDate(for: a) ?? .distantPast) > (lastModifiedDate(for: b) ?? .distantPast)
            }
        }
    }

    var body: some View {
        Group {
            if isScanning {
                ProgressView("Scanning…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if projects.isEmpty {
                /*ContentUnavailableView(
                    "No Projects Found",
                    systemImage: "magnifyingglass",
                    description: Text("No Xcode projects or Swift packages were found in this directory.")
                )*/
                EmptyView()
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selection) {
                        let xcodeProjects = filteredProjects.filter { $0.kind == .xcodeProject }
                        let swiftPackages = filteredProjects.filter { $0.kind == .swiftPackage }

                        if !xcodeProjects.isEmpty {
                            Section("Xcode Projects", isExpanded: $isXcodeProjectsExpanded) {
                                ForEach(xcodeProjects) { project in
                                    projectRow(project)
                                }
                            }
                        }

                        if !swiftPackages.isEmpty {
                            Section("Swift Packages", isExpanded: $isSwiftPackagesExpanded) {
                                ForEach(swiftPackages) { project in
                                    projectRow(project)
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            TextField("Filter", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)

                            Menu {
                                Button {
                                    settings.projectSortOrder = .alphabetical
                                } label: {
                                    if settings.projectSortOrder == .alphabetical {
                                        Label("Alphabetical", systemImage: "checkmark")
                                    } else {
                                        Text("Alphabetical")
                                    }
                                }
                                Button {
                                    settings.projectSortOrder = .recentlyChanged
                                } label: {
                                    if settings.projectSortOrder == .recentlyChanged {
                                        Label("Recently Changed", systemImage: "checkmark")
                                    } else {
                                        Text("Recently Changed")
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .buttonStyle(.plain)

                            if !settings.availableTags.isEmpty {
                                Menu {
                                    ForEach(settings.availableTags, id: \.self) { tag in
                                        Button {
                                            if activeTagFilters.contains(tag) {
                                                activeTagFilters.remove(tag)
                                            } else {
                                                activeTagFilters.insert(tag)
                                            }
                                        } label: {
                                            if activeTagFilters.contains(tag) {
                                                Label(tag, systemImage: "checkmark")
                                            } else {
                                                Text(tag)
                                            }
                                        }
                                    }
                                    if !activeTagFilters.isEmpty {
                                        Divider()
                                        Button("Clear Filters") {
                                            activeTagFilters.removeAll()
                                        }
                                    }
                                } label: {
                                    Image(systemName: activeTagFilters.isEmpty ? "tag" : "tag.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Material.ultraThin)
                    }
                    .alert("New Tag", isPresented: $isShowingNewTagAlert) {
                        TextField("Tag name", text: $newTagName)
                        Button("Add") {
                            let name = newTagName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            if !settings.availableTags.contains(name) {
                                settings.availableTags.append(name)
                            }
                            if let project = newTagTargetProject {
                                var tags = settings.tags(for: project)
                                if !tags.contains(name) {
                                    tags.append(name)
                                    settings.setTags(tags, for: project)
                                }
                            }
                            newTagTargetProject = nil
                        }
                        Button("Cancel", role: .cancel) {
                            newTagTargetProject = nil
                        }
                    } message: {
                        Text("Enter a name for the new tag.")
                    }
                    .onChange(of: selection) {
                        if let selection {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(selection.id, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var isSelected: (DiscoveredProject) -> Bool {
        { project in selection?.id == project.id }
    }

    private func projectRow(_ project: DiscoveredProject) -> some View {
        let selected = isSelected(project)
        return HStack(spacing: 6) {
            projectIcon(for: project, selected: selected)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .lineLimit(1)
                if let date = lastModifiedDate(for: project) {
                    Text(date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                let tags = settings.tags(for: project)
                if !tags.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.purple.opacity(0.15), in: Capsule())
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
        }
        .tag(project)
        .contextMenu { projectContextMenu(for: project) }
    }

    private func lastModifiedDate(for project: DiscoveredProject) -> Date? {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        return try? FileManager.default
            .attributesOfItem(atPath: directory.path(percentEncoded: false))[.modificationDate] as? Date
    }

    @ViewBuilder
    private func projectIcon(for project: DiscoveredProject, selected: Bool) -> some View {
        switch project.kind {
        case .xcodeProject:
            Image(systemName: "hammer.fill")
                .font(.system(size: 7))
                .foregroundStyle(selected ? .white : .black)
                .frame(width: 14, height: 14)
                .offset(x: 0.5, y: -0.5)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(selected ? .white.opacity(0.3) : .blue)
                )
        case .swiftPackage:
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(selected ? .white : project.iconColor)
        }
    }

    @ViewBuilder
    private func projectContextMenu(for project: DiscoveredProject) -> some View {
        if settings.favoriteProjectPaths.contains(project.stablePath) {
            Button("Remove from Favorites", systemImage: "star.slash") {
                settings.favoriteProjectPaths.removeAll { $0 == project.stablePath }
            }
        } else {
            Button("Add to Favorites", systemImage: "star") {
                settings.favoriteProjectPaths.append(project.stablePath)
            }
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
        Divider()
        Menu("Tags") {
            ForEach(settings.availableTags, id: \.self) { tag in
                Button {
                    settings.toggleTag(tag, for: project)
                } label: {
                    if settings.tags(for: project).contains(tag) {
                        Label(tag, systemImage: "checkmark")
                    } else {
                        Text(tag)
                    }
                }
            }
            Divider()
            Button("New Tag…") {
                newTagName = ""
                newTagTargetProject = project
                isShowingNewTagAlert = true
            }
        }
        Divider()
        Button("Copy Path", systemImage: "doc.on.doc") {
            let directory = switch project.kind {
            case .xcodeProject: project.url.deletingLastPathComponent()
            case .swiftPackage: project.url
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(directory.path(percentEncoded: false), forType: .string)
        }
    }
}
