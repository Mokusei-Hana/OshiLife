import Foundation
import UIKit

enum MapProvider: String, CaseIterable, Identifiable {
    case apple
    case google

    var id: Self { self }
}

enum MapServiceError: LocalizedError, Equatable {
    case emptyVenue
    case missingCoordinates
    case invalidMapURL

    var errorDescription: String? {
        switch self {
        case .emptyVenue: String(localized: "error.map_empty")
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
        latitude: Double? = nil,
        longitude: Double? = nil
    ) throws {
        let trimmedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        let url: URL
        if !trimmedVenue.isEmpty {
            url = switch provider {
            case .apple: try Self.appleMapsURL(venue: trimmedVenue)
            case .google: try Self.googleMapsURL(venue: trimmedVenue)
            }
        } else {
            let coordinateQuery = try Self.coordinateQuery(
                latitude: latitude,
                longitude: longitude
            )
            url = switch provider {
            case .apple: try Self.appleMapsURL(venue: coordinateQuery)
            case .google: try Self.googleMapsURL(venue: coordinateQuery)
            }
        }
        // Universal map links open an installed app and remain valid browser fallbacks.
        UIApplication.shared.open(url)
    }

    static func appleMapsURL(venue: String) throws -> URL {
        try mapsURL(
            scheme: "http",
            host: "maps.apple.com",
            path: "/",
            venue: venue
        )
    }

    static func googleMapsURL(venue: String) throws -> URL {
        try mapsURL(
            scheme: "https",
            host: "www.google.com",
            path: "/maps/search/",
            venue: venue,
            includesAPIParameter: true
        )
    }

    static func hasValidCoordinates(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    static func googleMapsURL(latitude: Double?, longitude: Double?) throws -> URL {
        try googleMapsURL(venue: coordinateQuery(latitude: latitude, longitude: longitude))
    }

    private static func coordinateQuery(
        latitude: Double?,
        longitude: Double?
    ) throws -> String {
        guard hasValidCoordinates(latitude: latitude, longitude: longitude),
              let latitude,
              let longitude else {
            throw MapServiceError.missingCoordinates
        }
        return "\(latitude),\(longitude)"
    }

    private static func mapsURL(
        scheme: String,
        host: String,
        path: String,
        venue: String,
        includesAPIParameter: Bool = false
    ) throws -> URL {
        let venue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !venue.isEmpty else {
            throw MapServiceError.emptyVenue
        }

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = includesAPIParameter
            ? [
                URLQueryItem(name: "api", value: "1"),
                URLQueryItem(name: "query", value: venue)
            ]
            : [URLQueryItem(name: "q", value: venue)]
        guard let url = components.url else { throw MapServiceError.invalidMapURL }
        return url
    }
}
