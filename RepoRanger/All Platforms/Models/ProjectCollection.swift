//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

struct ProjectCollection: Codable, Identifiable, Hashable {

    let id: UUID
    var name: String
    var tagFilters: [String]
    var kindFilter: KindFilter
    var timeLimit: TimeLimit
    var directoryID: UUID?
    var readmeFilter: TriStateFilter
    var gitRepoFilter: TriStateFilter
    var sortOrder: ProjectSortOrder

    init(
        id: UUID = UUID(),
        name: String,
        tagFilters: [String] = [],
        kindFilter: KindFilter = .all,
        timeLimit: TimeLimit = .noLimit,
        directoryID: UUID? = nil,
        readmeFilter: TriStateFilter = .any,
        gitRepoFilter: TriStateFilter = .any,
        sortOrder: ProjectSortOrder = .recentlyChanged
    ) {
        self.id = id
        self.name = name
        self.tagFilters = tagFilters
        self.kindFilter = kindFilter
        self.timeLimit = timeLimit
        self.directoryID = directoryID
        self.readmeFilter = readmeFilter
        self.gitRepoFilter = gitRepoFilter
        self.sortOrder = sortOrder
    }

    enum TriStateFilter: String, Codable, Hashable, CaseIterable {
        case any
        case yes
        case no

        func displayName(for label: String) -> String {
            switch self {
            case .any: "Any"
            case .yes: "Has \(label)"
            case .no: "No \(label)"
            }
        }
    }

    enum KindFilter: String, Codable, Hashable, CaseIterable {
        case all
        case xcodeOnly
        case swiftPackageOnly

        var displayName: String {
            switch self {
            case .all: "All"
            case .xcodeOnly: "Xcode Projects Only"
            case .swiftPackageOnly: "Swift Packages Only"
            }
        }
    }

    enum TimeLimit: String, Codable, Hashable, CaseIterable {
        case oneMonth
        case threeMonths
        case sixMonths
        case oneYear
        case noLimit

        var displayName: String {
            switch self {
            case .oneMonth: "1 Month"
            case .threeMonths: "3 Months"
            case .sixMonths: "6 Months"
            case .oneYear: "1 Year"
            case .noLimit: "No Limit"
            }
        }

        var cutoffDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
            case .oneYear: return calendar.date(byAdding: .year, value: -1, to: Date())
            case .noLimit: return nil
            }
        }
    }
}
