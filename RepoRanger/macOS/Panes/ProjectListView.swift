//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ProjectListView: View {

    let projects: [DiscoveredProject]
    let isScanning: Bool
    @Binding var selection: DiscoveredProject?

    @State private var isXcodeProjectsExpanded = true
    @State private var isSwiftPackagesExpanded = true
    @State private var searchText = ""

    private var filteredProjects: [DiscoveredProject] {
        if searchText.isEmpty { return projects }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if isScanning {
                ProgressView("Scanning…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if projects.isEmpty {
                ContentUnavailableView(
                    "No Projects Found",
                    systemImage: "magnifyingglass",
                    description: Text("No Xcode projects or Swift packages were found in this directory.")
                )
            } else {
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
                .searchable(text: $searchText, placement: .sidebar, prompt: "Filter")
            }
        }
    }

    private func projectRow(_ project: DiscoveredProject) -> some View {
        HStack(spacing: 6) {
            projectIcon(for: project)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .lineLimit(1)
                Text(project.parentName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .tag(project)
        .contextMenu { projectContextMenu(for: project) }
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

    @ViewBuilder
    private func projectContextMenu(for project: DiscoveredProject) -> some View {
        Button("Reveal in Finder") {
            let directory = switch project.kind {
            case .xcodeProject: project.url.deletingLastPathComponent()
            case .swiftPackage: project.url
            }
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path(percentEncoded: false))
        }
        Button("Open in Xcode") {
            let url = switch project.kind {
            case .xcodeProject: project.url
            case .swiftPackage: project.url.appendingPathComponent("Package.swift")
            }
            let xcodeURL = URL(filePath: "/Applications/Xcode.app")
            NSWorkspace.shared.open([url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}
