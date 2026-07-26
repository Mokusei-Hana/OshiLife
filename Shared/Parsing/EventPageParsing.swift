import Foundation

/// Parses a fetched event page into structured import details.
///
/// Add support for a new event site by implementing this protocol and
/// registering the parser in `EventLinkImporter`'s default parser list.
protocol EventPageParsing: Sendable {
    func supports(_ url: URL) -> Bool
    func parse(html: String, sourceURL: URL) -> EventImportDetails?
}
