import Foundation

enum PerformerCatalog {
    static func uniqueNames(_ names: [String]) -> [String] {
        names.reduce(into: []) { result, name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  !result.contains(where: {
                      $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                  })
            else { return }
            result.append(trimmed)
        }
    }

    static func namesByUsage(in events: [LiveEvent]) -> [String] {
        let counts = events
            .flatMap(\.performers)
            .reduce(into: [String: Int]()) { counts, performer in
                let trimmed = performer.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                counts[trimmed, default: 0] += 1
            }

        return counts.keys.sorted { lhs, rhs in
            let lhsCount = counts[lhs, default: 0]
            let rhsCount = counts[rhs, default: 0]
            if lhsCount != rhsCount { return lhsCount > rhsCount }
            return lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    static func collapsedNames(
        from names: [String],
        selected: Set<String>,
        limit: Int
    ) -> [String] {
        guard limit > 0 else {
            return names.filter(selected.contains)
        }

        let selectedNames = names.filter(selected.contains)
        let remainingCount = max(0, limit - selectedNames.count)
        let unselectedNames = names.filter { !selected.contains($0) }
        return selectedNames + unselectedNames.prefix(remainingCount)
    }
}
