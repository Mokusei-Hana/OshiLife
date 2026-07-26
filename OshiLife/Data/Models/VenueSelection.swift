import CoreLocation
import Foundation

struct VenueSelection: Equatable, Sendable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    init(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.address = address
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    init(name: String, address: String, latitude: Double, longitude: Double) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
}
