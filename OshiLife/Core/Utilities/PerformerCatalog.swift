import Foundation

enum PerformerCatalog {
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
}
