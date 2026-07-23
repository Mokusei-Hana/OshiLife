import Foundation
import MapKit
import UIKit

enum MapProvider: String, CaseIterable, Identifiable {
    case apple
    case google

    var id: Self { self }
}

enum MapServiceError: LocalizedError, Equatable {
    case missingCoordinates
    case invalidMapURL

    var errorDescription: String? {
        switch self {
        case .missingCoordinates: String(localized: "error.map_coordinates")
        case .invalidMapURL: String(localized: "error.map_url")
        }
    }
}

@MainActor
struct MapService {
    func open(
        provider: MapProvider,
        venue: String,
        latitude: Double?,
        longitude: Double?
    ) throws {
        let coordinate = try Self.coordinate(latitude: latitude, longitude: longitude)

        switch provider {
        case .apple:
            let item = MKMapItem(
                location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                address: nil
            )
            let trimmedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedVenue.isEmpty { item.name = trimmedVenue }
            item.openInMaps()
        case .google:
            UIApplication.shared.open(try Self.googleMapsURL(for: coordinate))
        }
    }

    static func hasValidCoordinates(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    static func googleMapsURL(latitude: Double?, longitude: Double?) throws -> URL {
        try googleMapsURL(for: coordinate(latitude: latitude, longitude: longitude))
    }

    private static func coordinate(
        latitude: Double?,
        longitude: Double?
    ) throws -> CLLocationCoordinate2D {
        guard hasValidCoordinates(latitude: latitude, longitude: longitude),
              let latitude,
              let longitude else {
            throw MapServiceError.missingCoordinates
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private static func googleMapsURL(for coordinate: CLLocationCoordinate2D) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/maps/search/"
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: "\(coordinate.latitude),\(coordinate.longitude)")
        ]
        guard let url = components.url else { throw MapServiceError.invalidMapURL }
        return url
    }
}
