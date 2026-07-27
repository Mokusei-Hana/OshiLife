import Foundation
@preconcurrency import MapKit
import Observation

@MainActor
@Observable
final class VenueSearchService: NSObject, @preconcurrency MKLocalSearchCompleterDelegate {
    var query = "" {
        didSet { completer.queryFragment = query.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    private(set) var suggestions: [MKLocalSearchCompletion] = []
    private(set) var isResolving = false
    var errorMessage: String?

    @ObservationIgnored private let completer: MKLocalSearchCompleter

    override init() {
        let completer = MKLocalSearchCompleter()
        self.completer = completer
        super.init()
        completer.resultTypes = [.pointOfInterest, .address]
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
        errorMessage = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        suggestions = []
        errorMessage = error.localizedDescription
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> VenueSelection? {
        isResolving = true
        defer { isResolving = false }

        do {
            let request = MKLocalSearch.Request(completion: completion)
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                errorMessage = String(localized: "error.map_no_result")
                return nil
            }

            let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = name?.isEmpty == false ? name! : completion.title
            let formattedAddress = item.address?.fullAddress
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let address = formattedAddress?.isEmpty == false ? formattedAddress! : completion.subtitle
            errorMessage = nil
            return VenueSelection(
                name: resolvedName,
                address: address,
                coordinate: item.location.coordinate
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
