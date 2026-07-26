import Foundation

/// Extracts schema.org Event data from `application/ld+json` script blocks.
enum JSONLDEventExtractor {
    struct ExtractedEvent: Sendable {
        var name: String?
        var startDate: Date?
        var startDateIncludesTime = false
        var endDate: Date?
        var doorTime: Date?
        var venueName: String?
        var performers: [String] = []
        var ticketOptions: [TicketOption] = []
        var imageURLString: String?
    }

    static func firstEvent(in html: String) -> ExtractedEvent? {
        for block in scriptBlocks(in: html) {
            guard let data = block.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else { continue }
            for candidate in eventObjects(in: json) {
                if let event = extract(from: candidate) { return event }
            }
        }
        return nil
    }

    private static func scriptBlocks(in html: String) -> [String] {
        let pattern = #"(?is)<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return expression.matches(in: html, range: NSRange(html.startIndex..., in: html)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[range])
        }
    }

    private static func eventObjects(in json: Any) -> [[String: Any]] {
        var candidates: [[String: Any]] = []
        if let object = json as? [String: Any] {
            candidates.append(object)
            if let graph = object["@graph"] as? [Any] {
                candidates.append(contentsOf: graph.compactMap { $0 as? [String: Any] })
            }
        } else if let array = json as? [Any] {
            candidates.append(contentsOf: array.compactMap { $0 as? [String: Any] })
        }
        return candidates.filter(isEvent)
    }

    private static func isEvent(_ object: [String: Any]) -> Bool {
        let types: [String]
        if let type = object["@type"] as? String {
            types = [type]
        } else if let list = object["@type"] as? [String] {
            types = list
        } else {
            return false
        }
        return types.contains { $0.localizedCaseInsensitiveContains("event") || $0.caseInsensitiveCompare("Festival") == .orderedSame }
    }

    private static func extract(from object: [String: Any]) -> ExtractedEvent? {
        var event = ExtractedEvent()
        event.name = string(object["name"])
        if let raw = string(object["startDate"]), let parsed = parseDate(raw) {
            event.startDate = parsed.date
            event.startDateIncludesTime = parsed.hasTime
        }
        if let raw = string(object["endDate"]), let parsed = parseDate(raw) {
            event.endDate = parsed.date
        }
        if let raw = string(object["doorTime"]), let parsed = parseDate(raw), parsed.hasTime {
            event.doorTime = parsed.date
        }
        event.venueName = locationName(object["location"])
        event.performers = names(object["performer"])
        event.ticketOptions = offers(object["offers"])
        event.imageURLString = imageURLString(object["image"])
        guard event.name != nil || event.startDate != nil || event.venueName != nil else { return nil }
        return event
    }

    // MARK: - Field helpers

    private static func string(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private static func locationName(_ value: Any?) -> String? {
        if let name = string(value) { return name }
        if let object = value as? [String: Any] {
            return string(object["name"]) ?? string(object["address"])
        }
        if let array = value as? [Any] {
            return array.lazy.compactMap { locationName($0) }.first
        }
        return nil
    }

    private static func names(_ value: Any?) -> [String] {
        if let name = string(value) { return [name] }
        if let object = value as? [String: Any] {
            return string(object["name"]).map { [$0] } ?? []
        }
        if let array = value as? [Any] {
            return array.flatMap { names($0) }
        }
        return []
    }

    private static func offers(_ value: Any?) -> [TicketOption] {
        let objects: [[String: Any]]
        if let object = value as? [String: Any] {
            objects = [object]
        } else if let array = value as? [Any] {
            objects = array.compactMap { $0 as? [String: Any] }
        } else {
            return []
        }
        return objects.prefix(20).compactMap { offer in
            let name = string(offer["name"]) ?? "チケット"
            let price = intPrice(offer["price"]) ?? intPrice(offer["lowPrice"])
            let description = string(offer["description"])
            guard price != nil || string(offer["name"]) != nil else { return nil }
            return TicketOption(name: name, price: price, description: description)
        }
    }

    private static func intPrice(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return Int(number.doubleValue) }
        guard let string = value as? String else { return nil }
        let cleaned = string.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        if let intValue = Int(cleaned) { return intValue }
        if let doubleValue = Double(cleaned) { return Int(doubleValue) }
        return nil
    }

    private static func imageURLString(_ value: Any?) -> String? {
        if let string = string(value) { return string }
        if let object = value as? [String: Any] { return string(object["url"]) }
        if let array = value as? [Any] {
            return array.lazy.compactMap { imageURLString($0) }.first
        }
        return nil
    }

    // MARK: - Dates

    /// Parses ISO 8601 style dates; values without an offset are assumed to be
    /// Japan Standard Time, matching the announcements this app imports.
    private static func parseDate(_ raw: String) -> (date: Date, hasTime: Bool)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("T") {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: trimmed) { return (date, true) }
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: trimmed) { return (date, true) }
            for format in ["yyyy-MM-dd'T'HH:mmXXXXX", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm"] {
                if let date = formatter(format).date(from: trimmed) { return (date, true) }
            }
            return nil
        }
        for format in ["yyyy-MM-dd", "yyyy/MM/dd"] {
            if let date = formatter(format).date(from: trimmed) { return (date, false) }
        }
        return nil
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = format
        return formatter
    }
}
