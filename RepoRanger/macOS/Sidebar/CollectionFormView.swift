//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct CollectionFormView: View {

    @Bindable var settings: AppSettings
    let collection: ProjectCollection?
    let onSave: (ProjectCollection) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var kindFilter: ProjectCollection.KindFilter = .all
    @State private var timeLimit: ProjectCollection.TimeLimit = .noLimit
    @State private var directoryID: UUID?
    @State private var selectedTags: Set<String> = []
    @State private var readmeFilter: ProjectCollection.TriStateFilter = .any
    @State private var gitRepoFilter: ProjectCollection.TriStateFilter = .any
    @State private var sortOrder: ProjectSortOrder = .recentlyChanged

    private var isEditing: Bool { collection != nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section {
                    Picker("Project Kind", selection: $kindFilter) {
                        ForEach(ProjectCollection.KindFilter.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }

                    Picker("Modified Within", selection: $timeLimit) {
                        ForEach(ProjectCollection.TimeLimit.allCases, id: \.self) { limit in
                            Text(limit.displayName).tag(limit)
                        }
                    }

                    Picker("Directory", selection: $directoryID) {
                        Text("All Directories").tag(UUID?.none)
                        Divider()
                        ForEach(settings.monitoredDirectories) { directory in
                            Text(directory.displayName).tag(UUID?.some(directory.id))
                        }
                    }

                    Picker("README", selection: $readmeFilter) {
                        ForEach(ProjectCollection.TriStateFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName(for: "README")).tag(filter)
                        }
                    }

                    Picker("Git Repo", selection: $gitRepoFilter) {
                        ForEach(ProjectCollection.TriStateFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName(for: "Git Repo")).tag(filter)
                        }
                    }

                    Picker("Sort By", selection: $sortOrder) {
                        Text("Alphabetical").tag(ProjectSortOrder.alphabetical)
                        Text("Recently Changed").tag(ProjectSortOrder.recentlyChanged)
                    }
                }

                if !settings.availableTags.isEmpty {
                    Section("Tags") {
                        ForEach(settings.availableTags, id: \.self) { tag in
                            Toggle(tag, isOn: Binding(
                                get: { selectedTags.contains(tag) },
                                set: { isOn in
                                    if isOn {
                                        selectedTags.insert(tag)
                                    } else {
                                        selectedTags.remove(tag)
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Create") {
                    let result = ProjectCollection(
                        id: collection?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        tagFilters: Array(selectedTags),
                        kindFilter: kindFilter,
                        timeLimit: timeLimit,
                        directoryID: directoryID,
                        readmeFilter: readmeFilter,
                        gitRepoFilter: gitRepoFilter,
                        sortOrder: sortOrder
                    )
                    onSave(result)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 380, height: settings.availableTags.isEmpty ? 280 : 400)
        .onAppear {
            if let collection {
                name = collection.name
                kindFilter = collection.kindFilter
                timeLimit = collection.timeLimit
                directoryID = collection.directoryID
                selectedTags = Set(collection.tagFilters)
                readmeFilter = collection.readmeFilter
                gitRepoFilter = collection.gitRepoFilter
                sortOrder = collection.sortOrder
            }
        }
    }
}
