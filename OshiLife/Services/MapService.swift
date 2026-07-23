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
    func open(
        venue: String,
        address: String,
        latitude: Double?,
        longitude: Double?
    ) async throws {
        if let latitude, let longitude,
           (-90...90).contains(latitude), (-180...180).contains(longitude) {
            let item = MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
            let trimmedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedVenue.isEmpty { item.name = trimmedVenue }
            item.openInMaps()
            return
        }

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
