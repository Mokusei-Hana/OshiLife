import Foundation

struct HeroinesEventPageParser: EventPageParsing, Sendable {
    func supports(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        return host == "heroines.jp" || host == "www.heroines.jp"
    }

    func parse(html: String, sourceURL: URL) -> EventImportDetails? {
        let text = Self.plainText(from: html)
        let eventText = Self.eventSection(in: text)
        guard let date = Self.eventDate(in: eventText) else { return nil }

        let title = Self.eventTitle(in: eventText, html: html)
        let venue = Self.firstCapture(#"(?:^|\n)\s*[@＠]\s*([^\n]+)"#, in: eventText)
            ?? Self.firstCapture(#"[@＠]\s*([^\n]+)"#, in: eventText)
            ?? Self.firstCapture(#"(?:会場|VENUE)\s*[：:]\s*([^\n]+)"#, in: eventText, caseInsensitive: true)
        let times = Self.times(in: eventText, eventDate: date)
        let performers = Self.performers(in: eventText)
        let ticketOptions = Self.ticketOptions(in: eventText)
        let ticketInformation = Self.ticketInformation(in: eventText, options: ticketOptions)

        guard title != nil || venue != nil || times.open != nil || times.start != nil else { return nil }
        return EventImportDetails(
            title: title,
            date: date,
            venue: venue,
            openTime: times.open,
            startTime: times.start,
            performers: performers,
            ticketOptions: ticketOptions,
            ticketInformation: ticketInformation,
            linkedURL: sourceURL
        )
    }

    private static func eventSection(in text: String) -> String {
        let patterns = [
            #"(?:【|〖)\s*(?:公演概要|イベント概要)\s*(?:】|〗)"#,
            #"(?:^|\n)\s*(?:公演概要|イベント概要)\s*(?:\n|$)"#
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range.upperBound...])
            }
        }
        return text
    }

    private static func plainText(from html: String) -> String {
        html
            .replacingOccurrences(of: #"(?is)<(script|style)\b[^>]*>.*?</\1>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)</(?:p|div|h[1-6]|li|section|article)>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func eventDate(in text: String) -> Date? {
        let patterns = [
            #"(?<!\d)(20\d{2})[年./-]\s*(\d{1,2})[月./-]\s*(\d{1,2})日?"#,
            #"(?<!\d)(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日"#
        ]
        for pattern in patterns {
            guard let values = captures(pattern, in: text, count: 3),
                  let year = Int(values[0]), let month = Int(values[1]), let day = Int(values[2]) else { continue }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                return date
            }
        }
        return nil
    }

    private static func eventTitle(in text: String, html: String) -> String? {
        if let quoted = firstCapture(#"(「[^」]+」)"#, in: text) {
            return quoted
        }
        let lines = text.components(separatedBy: .newlines)
        if let dateIndex = lines.firstIndex(where: { eventDate(in: $0) != nil }) {
            let preceding = lines[..<dateIndex].reversed().prefix(2).first(where: isLikelyTitle)
            if let preceding, preceding.range(of: #"公演概要|イベント概要"#, options: .regularExpression) == nil {
                return preceding
            }
            if let following = lines.dropFirst(dateIndex + 1).prefix(4).first(where: isLikelyTitle) {
                return following
            }
        }
        if let heading = firstCapture(#"(?is)<h1\b[^>]*>(.*?)</h1>"#, in: html) {
            let clean = plainText(from: heading)
            if let quoted = firstCapture(#"(「[^」]+」)"#, in: clean) {
                return quoted
            }
            if !clean.isEmpty, clean != "NEWS" { return clean }
        }
        return nil
    }

    private static func isLikelyTitle(_ line: String) -> Bool {
        !line.hasPrefix("@") &&
        !line.hasPrefix("＠") &&
        line.range(
            of: #"^(?:OPEN|START|開場|開演|出演|会場|チケット|前方|一般|注意|※|▼|【|〖)"#,
            options: [.regularExpression, .caseInsensitive]
        ) == nil
    }

    private static func times(in text: String, eventDate: Date) -> (open: Date?, start: Date?) {
        if let combined = captures(
            #"(?:OPEN|開場)\s*/\s*(?:START|開演)\s*[：:]?\s*(\d{1,2}:\d{2})\s*/\s*(\d{1,2}:\d{2})"#,
            in: text,
            count: 2,
            caseInsensitive: true
        ) {
            return (time(combined[0], on: eventDate), time(combined[1], on: eventDate))
        }
        let open = firstCapture(#"(?:OPEN|開場)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})"#, in: text, caseInsensitive: true)
        let start = firstCapture(#"(?:START|開演)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})"#, in: text, caseInsensitive: true)
        return (time(open, on: eventDate), time(start, on: eventDate))
    }

    private static func time(_ value: String?, on date: Date) -> Date? {
        guard let value else { return nil }
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date)
    }

    private static func performers(in text: String) -> [String] {
        guard let raw = firstCapture(#"(?:出演|出演者|ACT)\s*[：:]\s*([^\n]+)"#, in: text, caseInsensitive: true) else {
            return []
        }
        return raw.components(separatedBy: CharacterSet(charactersIn: "/／、,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func ticketInformation(in text: String, options: [TicketOption]) -> String? {
        let lines = text.components(separatedBy: .newlines)
        guard let index = lines.firstIndex(where: {
            $0.range(of: #"チケット|TICKET"#, options: [.regularExpression, .caseInsensitive]) != nil
        }) else { return nil }
        let result = lines[index...]
            .prefix(max(8, options.count + 1))
            .joined(separator: "\n")
        return result.isEmpty ? nil : result
    }

    private static func ticketOptions(in text: String) -> [TicketOption] {
        let lines = text.components(separatedBy: .newlines)
        let startIndex: Int
        if let headerIndex = lines.firstIndex(where: {
            $0.range(
                of: #"^(?:▼\s*)?(?:チケット情報|チケット販売|TICKET(?:\s+INFORMATION)?)"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil && ticketOption(from: $0) == nil
        }) {
            startIndex = headerIndex + 1
        } else {
            startIndex = lines.firstIndex(where: { ticketOption(from: $0) != nil }) ?? lines.count
        }

        var options: [TicketOption] = []
        for line in lines.dropFirst(startIndex).prefix(20) {
            if line.range(of: #"^(?:注意|備考|※|▼|【|出演|会場|OPEN|START)"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if !options.isEmpty { break }
                continue
            }
            guard let option = ticketOption(from: line) else {
                if !options.isEmpty, !line.isEmpty { break }
                continue
            }
            options.append(option)
        }
        return options
    }

    private static func ticketOption(from line: String) -> TicketOption? {
        let pattern = #"^\s*(.+?)\s*(?:[¥￥]\s*)?([0-9][0-9,]*)\s*円?(?:\s+(.+))?\s*$"#
        guard let values = captures(pattern, in: line, count: 3) else {
            return nil
        }
        guard let price = Int(values[1].replacingOccurrences(of: ",", with: "")) else {
            return nil
        }
        let rawName = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard rawName.range(of: #"チケット|券|TICKET"#, options: [.regularExpression, .caseInsensitive]) != nil else {
            return nil
        }
        let description = values.count > 2
            ? values[2].trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        return TicketOption(
            name: rawName,
            price: price,
            description: description.isEmpty ? nil : description
        )
    }

    private static func captures(
        _ pattern: String,
        in text: String,
        count: Int,
        caseInsensitive: Bool = false
    ) -> [String]? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > count else { return nil }
        return (1...count).compactMap {
            guard let range = Range(match.range(at: $0), in: text) else { return nil }
            return String(text[range])
        }
    }

    private static func firstCapture(
        _ pattern: String,
        in text: String,
        caseInsensitive: Bool = false
    ) -> String? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
