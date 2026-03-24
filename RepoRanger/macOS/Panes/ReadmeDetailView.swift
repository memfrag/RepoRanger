//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct ReadmeDetailView: View {

    @Bindable var settings: AppSettings
    @Environment(\.openURL) private var openURL
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
            ToolbarSpacer(.flexible)
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
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .automatic) {
                Button {
                    browseOnGitHub()
                } label: {
                    Label {
                        Text("Browse on GitHub")
                    } icon: {
                        Image(.github)
                            .resizable()
                            .frame(width: 18, height: 18)
                            .padding(4)
                    }
                }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .automatic) {
                Button {
                    openInSourceTree()
                } label: {
                    Label("Open in SourceTree", image: .branch)
                }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .automatic) {
                Button {
                    revealInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .automatic) {
                Button {
                    openInXcode()
                } label: {
                    Label {
                        Text("Open in Xcode")
                    } icon: {
                        Image(.xcode32)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .sharedBackgroundVisibility(.hidden)
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

    private func browseOnGitHub() {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        let configURL = directory.appendingPathComponent(".git/config")
        guard let contents = try? String(contentsOf: configURL, encoding: .utf8) else { return }
        var inOrigin = false
        var remoteURL: String?
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") {
                inOrigin = trimmed == "[remote \"origin\"]"
                continue
            }
            if inOrigin, trimmed.hasPrefix("url") {
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    remoteURL = parts[1].trimmingCharacters(in: .whitespaces)
                }
                break
            }
        }
        guard var urlString = remoteURL, !urlString.isEmpty else { return }
        if urlString.hasPrefix("git@") {
            // git@github.com:user/repo.git → https://github.com/user/repo.git
            urlString.replace(/^git@([^:]+):/) { match in
                "https://\(match.1)/"
            }
        }
        if urlString.hasSuffix(".git") {
            urlString = String(urlString.dropLast(4))
        }
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }

    private func revealInFinder() {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path(percentEncoded: false))
    }

    private func openInSourceTree() {
        let directory = switch project.kind {
        case .xcodeProject: project.url.deletingLastPathComponent()
        case .swiftPackage: project.url
        }
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = ["/Applications/SourceTree.app/Contents/Resources/stree", directory.path(percentEncoded: false)]
        try? process.run()
    }

    private func openInXcode() {
        project.openInXcode()
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
