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
                    let xcodeProjects = projects.filter { $0.kind == .xcodeProject }
                    let swiftPackages = projects.filter { $0.kind == .swiftPackage }

                    if !xcodeProjects.isEmpty {
                        Section("Xcode Projects", isExpanded: $isXcodeProjectsExpanded) {
                            ForEach(xcodeProjects) { project in
                                Label(project.name, systemImage: project.systemImage)
                                    .tag(project)
                                    .contextMenu { projectContextMenu(for: project) }
                            }
                        }
                    }

                    if !swiftPackages.isEmpty {
                        Section("Swift Packages", isExpanded: $isSwiftPackagesExpanded) {
                            ForEach(swiftPackages) { project in
                                Label(project.name, systemImage: project.systemImage)
                                    .tag(project)
                                    .contextMenu { projectContextMenu(for: project) }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
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
