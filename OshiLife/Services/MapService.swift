import Foundation
import MapKit

enum MapServiceError: LocalizedError {
    case emptyQuery
    case noResult

    var errorDescription: String? {
        switch self {
        case .emptyQuery: String(localized: "error.map_empty")
        case .noResult: String(localized: "error.map_no_result")
        }
    }
}

@MainActor
struct MapService {
    func open(venue: String, address: String) async throws {
        let query = [venue, address]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !query.isEmpty else { throw MapServiceError.emptyQuery }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let response = try await MKLocalSearch(request: request).start()
        guard let result = response.mapItems.first else { throw MapServiceError.noResult }
        result.openInMaps()
    }
}
