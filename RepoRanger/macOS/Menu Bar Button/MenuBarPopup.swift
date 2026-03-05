//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct MenuBarPopup: View {

    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if settings.favoriteProjectPaths.isEmpty {
                Text("No Favorites")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(settings.favoriteProjectPaths, id: \.self) { path in
                            FavoriteRow(path: path) {
                                withAnimation(.snappy) {
                                    settings.favoriteProjectPaths.removeAll { $0 == path }
                                }
                            }
                        }
                    }
                    .padding(6)
                }
            }
        }
        .frame(width: 260)
        .frame(minHeight: 100)
        .frame(maxHeight: 500)
    }
}

private struct FavoriteRow: View {

    let path: String
    let removeFromFavorites: () -> Void

    @State private var isHovered = false

    private var name: String {
        let url = URL(filePath: path)
        if url.pathExtension == "xcodeproj" {
            return url.deletingPathExtension().lastPathComponent
        }
        return url.lastPathComponent
    }

    private var isXcodeProject: Bool {
        URL(filePath: path).pathExtension == "xcodeproj"
    }

    var body: some View {
        Button {
            openInXcode()
        } label: {
            HStack(spacing: 6) {
                Group {
                    if isXcodeProject {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(.white)
                            .frame(width: 14, height: 14)
                            .offset(x: 0.5, y: -0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.blue)
                            )
                    } else {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(Color(red: 0xCA / 255.0, green: 0xA5 / 255.0, blue: 0x7C / 255.0))
                    }
                }
                Text(name)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.1))
                    .opacity(isHovered ? 1 : 0)
            )
            .padding(2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Reveal in Finder", systemImage: "folder") {
                revealInFinder()
            }
            Divider()
            Button("Remove from Favorites", systemImage: "star.slash", role: .destructive) {
                removeFromFavorites()
            }
        }
    }

    private func openInXcode() {
        let url: URL
        if isXcodeProject {
            url = URL(filePath: path)
        } else {
            url = URL(filePath: path).appendingPathComponent("Package.swift")
        }
        let xcodeURL = URL(filePath: "/Applications/Xcode.app")
        NSWorkspace.shared.open([url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration())
    }

    private func revealInFinder() {
        let directory: String
        if isXcodeProject {
            directory = URL(filePath: path).deletingLastPathComponent().path(percentEncoded: false)
        } else {
            directory = path
        }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory)
    }
}
