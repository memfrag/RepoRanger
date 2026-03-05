//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct ReadmeDetailView: View {

    @Bindable var settings: AppSettings
    let project: DiscoveredProject

    @State private var document: MarkdownDocument?
    @State private var loadError: Bool = false
    @State private var metadata: ProjectMetadata?

    var body: some View {
        VStack(spacing: 0) {
            if let metadata, !metadataPills(metadata).isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(metadataPills(metadata), id: \.label) { pill in
                        HStack(spacing: 4) {
                            Image(systemName: pill.icon)
                            Text(pill.label)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pill.tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(pill.tint)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Group {
                if let document {
                    ScrollView {
                        Markdown(document, lazy: true)
                            .markdownStyle(MarkdownStyle())
                            .tint(.blue)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .textSelection(.enabled)
                    }
                } else if loadError {
                    ContentUnavailableView(
                        "No README",
                        systemImage: "doc.text",
                        description: Text("This project does not have a README file.")
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    toggleFavorite()
                } label: {
                    Label(
                        isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: isFavorite ? "star.fill" : "star"
                    )
                }
                .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    revealInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    openInXcode()
                } label: {
                    Label("Open in Xcode", systemImage: "hammer.fill")
                }
            }
        }
        .task(id: project.id) {
            async let readmeTask: Void = loadReadme()
            async let metadataTask = ProjectMetadataExtractor.extract(from: project)
            let fetchedMetadata = await metadataTask
            await readmeTask
            metadata = fetchedMetadata
        }
    }

    private var isFavorite: Bool {
        settings.favoriteProjectPaths.contains(project.stablePath)
    }

    private func toggleFavorite() {
        if isFavorite {
            settings.favoriteProjectPaths.removeAll { $0 == project.stablePath }
        } else {
            settings.favoriteProjectPaths.append(project.stablePath)
        }
    }

    private func revealInFinder() {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path(percentEncoded: false))
    }

    private func openInXcode() {
        let url = switch project.kind {
        case .xcodeProject: project.url
        case .swiftPackage: project.url.appendingPathComponent("Package.swift")
        }
        let xcodeURL = URL(filePath: "/Applications/Xcode.app")
        NSWorkspace.shared.open([url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration())
    }

    private struct PillItem {
        let icon: String
        let label: String
        let tint: Color
    }

    private func metadataPills(_ metadata: ProjectMetadata) -> [PillItem] {
        var pills: [PillItem] = []
        if let version = metadata.swiftToolsVersion {
            pills.append(PillItem(icon: "swift", label: "Swift \(version)", tint: .orange))
        }
        for target in metadata.deploymentTargets {
            pills.append(PillItem(icon: "desktopcomputer", label: target, tint: .secondary))
        }
        if metadata.hasUncommittedChanges {
            pills.append(PillItem(icon: "exclamationmark.circle", label: "Modified", tint: .orange))
        }
        return pills
    }

    private func loadReadme() async {
        document = nil
        loadError = false

        guard let readmeURL = project.readmeURL else {
            loadError = true
            return
        }

        do {
            let contents = try String(contentsOf: readmeURL, encoding: .utf8)
            document = try MarkdownDocument(contents)
        } catch {
            loadError = true
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty && currentWidth + spacing + size.width > maxWidth {
                rows.append([])
                currentWidth = 0
            }
            if currentWidth > 0 { currentWidth += spacing }
            currentWidth += size.width
            rows[rows.count - 1].append(subview)
        }
        return rows
    }
}
