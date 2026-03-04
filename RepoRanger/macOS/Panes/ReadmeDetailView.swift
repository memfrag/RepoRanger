//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct ReadmeDetailView: View {

    let project: DiscoveredProject

    @State private var document: MarkdownDocument?
    @State private var loadError: Bool = false

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    Markdown(document, lazy: true)
                        .markdownStyle(MarkdownStyle())
                        .tint(.blue)
                        .padding()
                        .padding(.horizontal)
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
        .navigationTitle(project.name)
        .toolbar {
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
            await loadReadme()
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
