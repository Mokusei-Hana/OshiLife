import Foundation

/// Field values recognized inside free-form Japanese event announcement text.
///
/// Every field is optional so callers can keep whatever was recognized even
/// when other fields could not be parsed (partial imports).
struct ParsedEventText: Sendable {
    var title: String?
    var date: Date?
    var endDate: Date?
    var openTime: Date?
    var startTime: Date?
    var venue: String?
    var performers: [String] = []
    var ticketOptions: [TicketOption] = []
    var ticketInformation: String?

    /// True when at least one field beyond a bare title was recognized.
    var hasEventSignals: Bool {
        date != nil || openTime != nil || startTime != nil || venue != nil
            || !performers.isEmpty || !ticketOptions.isEmpty
    }

    /// Converts the recognized fields into import details, or nil when the
    /// text did not contain any recognizable event information.
    func details(linkedURL: URL) -> EventImportDetails? {
        guard hasEventSignals else { return nil }
        return EventImportDetails(
            title: title,
            date: date,
            endDate: endDate,
            venue: venue,
            openTime: openTime,
            startTime: startTime,
            performers: performers,
            ticketOptions: ticketOptions,
            ticketInformation: ticketInformation,
            linkedURL: linkedURL
        )
    }
}

/// Parses common Japanese event announcement formats such as
/// `日程：2026年8月7日(金)-9日(日)`, `開場 / 開演：09:00 / 10:00`,
/// `会場：KT Zepp Yokohama`, `出演：A / B` and `料金：一般 ¥5,000`.
///
/// The parser is label driven rather than site specific, tolerates full-width
/// characters and mixed separators, and never fails as a whole: unrecognized
/// fields are simply left nil.
enum JapaneseEventTextParser {
    private static let rangeSeparator = #"[-〜～~‐–—ー]"#
    private static let fieldLabelPrefix =
        #"^(?:日程|日時|開催日|公演日|会場|場所|出演者?|料金|チケット|前売り?|当日|注意|備考|OPEN|START|開場|開演|VENUE|TICKET|LINE\s*UP|※|▼|▶|●|■|【[^】]*】$|@\s)"#

    static func parse(_ text: String) -> ParsedEventText {
        let normalized = normalize(text)
        let lines = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result = ParsedEventText()
        let dates = parseDates(in: normalized)
        result.date = dates?.start
        result.endDate = dates?.end
        let anchor = dates?.start ?? referenceDay
        let times = parseTimes(in: normalized)
        result.openTime = resolve(times.open, on: anchor)
        result.startTime = resolve(times.start, on: anchor)
        result.venue = parseVenue(in: normalized)
        result.performers = parsePerformers(in: normalized, lines: lines)
        let tickets = parseTickets(in: lines)
        result.ticketOptions = tickets.options
        result.ticketInformation = tickets.information
        result.title = parseTitle(in: normalized, lines: lines)
        return result
    }

    // MARK: - Normalization

    /// Maps full-width ASCII (digits, letters, punctuation) to half-width so
    /// each field pattern only needs to match one representation. Kana and
    /// kanji are left untouched; wave dashes are handled inside the patterns.
    static func normalize(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0xFF01...0xFF5D:
                scalars.append(Unicode.Scalar(scalar.value - 0xFEE0)!)
            case 0xFFE5: // ￥
                scalars.append("\u{00A5}")
            case 0x3000: // ideographic space
                scalars.append(" ")
            default:
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    // MARK: - Dates

    private struct DayComponents {
        var year: Int
        var month: Int
        var day: Int
    }

    private static func parseDates(in text: String) -> (start: Date, end: Date?)? {
        let scopes = labeledLineTails(for: #"日程|日時|開催日|公演日"#, in: text) + [text]
        for scope in scopes {
            if let range = dateRange(in: scope) { return range }
        }
        return nil
    }

    /// Recognizes a single date or a multi-day range such as
    /// `2026/8/7(金)〜8/9(日)` or `2026年8月7日(金)-9日(日)`. Also used by
    /// site-specific parsers whose pages share these announcement formats.
    static func dateRange(in text: String) -> (start: Date, end: Date?)? {
        let weekday = #"(?:\([^)\n]{1,6}\))?"#
        let rangePatterns = [
            #"(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日?\s*"# + weekday
                + #"\s*"# + rangeSeparator
                + #"\s*(?:(20\d{2})\s*年\s*)?(?:(\d{1,2})\s*月\s*)?(\d{1,2})\s*日?"#,
            #"(?<!\d)(20\d{2})[/.](\d{1,2})[/.](\d{1,2})\s*"# + weekday
                + #"\s*"# + rangeSeparator
                + #"\s*(?:(20\d{2})[/.])?(?:(\d{1,2})[/.])?(\d{1,2})(?!\d)"#
        ]
        for pattern in rangePatterns {
            guard let match = firstMatch(pattern, in: text),
                  let start = day(year: match[0], month: match[1], day: match[2]),
                  let startDate = date(from: start) else { continue }
            let end = day(
                year: match[3] ?? String(start.year),
                month: match[4] ?? String(start.month),
                day: match[5]
            )
            if let end, let endDate = date(from: end), endDate > startDate {
                return (startDate, endDate)
            }
            return (startDate, nil)
        }

        let singlePatterns = [
            #"(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日?"#,
            #"(?<!\d)(20\d{2})[/.\-](\d{1,2})[/.\-](\d{1,2})(?!\d)"#
        ]
        for pattern in singlePatterns {
            guard let match = firstMatch(pattern, in: text),
                  let components = day(year: match[0], month: match[1], day: match[2]),
                  let startDate = date(from: components) else { continue }
            return (startDate, nil)
        }
        return nil
    }

    private static func day(year: String?, month: String?, day: String?) -> DayComponents? {
        guard let year = year.flatMap({ Int($0) }),
              let month = month.flatMap({ Int($0) }),
              let day = day.flatMap({ Int($0) }),
              (1...12).contains(month), (1...31).contains(day) else { return nil }
        return DayComponents(year: year, month: month, day: day)
    }

    private static func date(from components: DayComponents) -> Date? {
        calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day))
    }

    // MARK: - Times

    private static func parseTimes(in text: String) -> (open: (hour: Int, minute: Int)?, start: (hour: Int, minute: Int)?) {
        let open = #"(?:OPEN|開場)"#
        let start = #"(?:START|開演)"#
        let time = #"(\d{1,2}):(\d{2})"#
        let combined = open + #"\s*[/・]\s*"# + start + #"\s*:?\s*"# + time
            + #"\s*(?:[/・]|"# + rangeSeparator + #")\s*"# + time
        if let match = firstMatch(combined, in: text, caseInsensitive: true),
           let openTime = clock(hour: match[0], minute: match[1]),
           let startTime = clock(hour: match[2], minute: match[3]) {
            return (openTime, startTime)
        }
        let openMatch = firstMatch(open + #"\s*:?\s*"# + time, in: text, caseInsensitive: true)
        let startMatch = firstMatch(start + #"\s*:?\s*"# + time, in: text, caseInsensitive: true)
        return (
            openMatch.flatMap { clock(hour: $0[0], minute: $0[1]) },
            startMatch.flatMap { clock(hour: $0[0], minute: $0[1]) }
        )
    }

    private static func clock(hour: String?, minute: String?) -> (hour: Int, minute: Int)? {
        guard let hour = hour.flatMap({ Int($0) }), let minute = minute.flatMap({ Int($0) }),
              (0...29).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    private static func resolve(_ time: (hour: Int, minute: Int)?, on day: Date) -> Date? {
        guard let time else { return nil }
        // Late-night listings such as 25:00 mean 1:00 on the following day.
        let dayOffset = time.hour / 24
        let anchor = dayOffset > 0 ? calendar.date(byAdding: .day, value: dayOffset, to: day) ?? day : day
        return calendar.date(bySettingHour: time.hour % 24, minute: time.minute, second: 0, of: anchor)
    }

    // MARK: - Venue

    private static func parseVenue(in text: String) -> String? {
        if let labeled = firstMatch(#"(?:会場|場所|VENUE|PLACE)\s*:\s*([^\n]+)"#, in: text, caseInsensitive: true),
           let venue = cleanedValue(labeled[0]) {
            return venue
        }
        // "@ KT Zepp Yokohama" style. Requiring whitespace after the marker
        // keeps X handles such as "@oshi_official" from being read as venues.
        if let atLine = firstMatch(#"(?:^|\n)\s*@[ \t]+([^\n]+)"#, in: text),
           let venue = cleanedValue(atLine[0]) {
            return venue
        }
        return nil
    }

    // MARK: - Performers

    private static func parsePerformers(in text: String, lines: [String]) -> [String] {
        let label = #"(?:出演者?|LINE\s*UP|LINEUP|ACT)"#
        if let labeled = firstMatch(label + #"[ \t]*:[ \t]*([^\n]+)"#, in: text, caseInsensitive: true),
           let value = cleanedValue(labeled[0]) {
            let names = splitList(value)
            if !names.isEmpty { return names }
        }
        // A bare "出演：" label with the members listed on the following lines.
        guard let labelIndex = lines.firstIndex(where: {
            $0.range(of: #"^"# + label + #"\s*:?\s*$"#, options: [.regularExpression, .caseInsensitive]) != nil
        }) else { return [] }
        var names: [String] = []
        for line in lines.dropFirst(labelIndex + 1).prefix(12) {
            if line.range(of: fieldLabelPrefix, options: [.regularExpression, .caseInsensitive]) != nil { break }
            names.append(contentsOf: splitList(line))
        }
        return names
    }

    private static func splitList(_ value: String) -> [String] {
        value
            .components(separatedBy: CharacterSet(charactersIn: "/／、,・|"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Tickets

    private static func parseTickets(in lines: [String]) -> (options: [TicketOption], information: String?) {
        var options: [TicketOption] = []
        var informationLines: [String] = []
        var seenNames = Set<String>()

        func append(_ option: TicketOption) {
            guard options.count < 20, seenNames.insert(option.name).inserted else { return }
            options.append(option)
        }

        for line in lines {
            if line.range(of: #"^(?:▼\s*)?(?:チケット(?:情報|販売|料金)?|TICKETS?(?:\s+INFORMATION)?)\s*$"#,
                          options: [.regularExpression, .caseInsensitive]) != nil {
                informationLines.append(line)
                continue
            }
            if let labeled = firstMatch(#"^(?:料金|チケット料金|チケット代|入場料|TICKET\s*PRICE)\s*:\s*(.+)$"#,
                                        in: line, caseInsensitive: true) {
                let recognized = ticketOptions(fromContent: labeled[0] ?? "")
                recognized.forEach(append)
                if !recognized.isEmpty { informationLines.append(line) }
                continue
            }
            if line.range(of: #"^[※•]"#, options: .regularExpression) != nil {
                // Notes such as "※通し券なし / 各税込" belong to the ticket
                // block when tickets were already found.
                if !options.isEmpty { informationLines.append(line) }
                continue
            }
            if hasPriceMarker(line),
               line.range(of: fieldLabelPrefix, options: [.regularExpression, .caseInsensitive]) == nil
               || line.range(of: #"^(?:チケット|前売り?|当日)"#, options: .regularExpression) != nil {
                let recognized = ticketOptions(fromContent: line)
                recognized.forEach(append)
                if !recognized.isEmpty { informationLines.append(line) }
            }
        }
        return (options, informationLines.isEmpty ? nil : informationLines.joined(separator: "\n"))
    }

    /// Parses a price listing that may contain several options separated by
    /// slashes, e.g. `前売 3,000円 / 当日 3,500円`. A single-option line is
    /// kept whole so slashes inside descriptions survive.
    private static func ticketOptions(fromContent content: String) -> [TicketOption] {
        let segments = priceMarkerCount(content) > 1
            ? content.components(separatedBy: CharacterSet(charactersIn: "/|"))
            : [content]
        return segments.compactMap(ticketOption(from:))
    }

    private static func hasPriceMarker(_ line: String) -> Bool {
        priceMarkerCount(line) > 0
    }

    private static func priceMarkerCount(_ line: String) -> Int {
        let yenSigns = line.filter { $0 == "¥" }.count
        guard let expression = try? NSRegularExpression(pattern: #"\d\s*円"#) else { return yenSigns }
        return yenSigns + expression.numberOfMatches(in: line, range: NSRange(line.startIndex..., in: line))
    }

    private static func ticketOption(from segment: String) -> TicketOption? {
        let patterns = [
            #"^\s*(.*?)\s*¥\s*([0-9][0-9,]{0,9})\s*円?\s*"# + rangeSeparator + #"?\s*(.*)$"#,
            #"^\s*(.*?)\s*(?<![,\d])([0-9][0-9,]{0,9})\s*円\s*"# + rangeSeparator + #"?\s*(.*)$"#
        ]
        for pattern in patterns {
            guard let match = firstMatch(pattern, in: segment),
                  let price = Int((match[1] ?? "").replacingOccurrences(of: ",", with: "")) else { continue }
            var name = (match[0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            name = name.trimmingCharacters(in: CharacterSet(charactersIn: ":：…"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count <= 30 else { return nil }
            if name.isEmpty { name = "チケット" }
            let description = (match[2] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return TicketOption(name: name, price: price, description: description.isEmpty ? nil : description)
        }
        return nil
    }

    // MARK: - Title

    private static func parseTitle(in text: String, lines: [String]) -> String? {
        if let quoted = firstMatch(#"『([^』\n]{1,80})』"#, in: text), let title = cleanedValue(quoted[0]) {
            return title
        }
        if let quoted = firstMatch(#"「([^」\n]{1,80})」"#, in: text), let title = cleanedValue(quoted[0]) {
            return title
        }
        for line in lines.prefix(8) where isLikelyTitle(line) {
            return line
        }
        return nil
    }

    private static func isLikelyTitle(_ line: String) -> Bool {
        guard (2...60).contains(line.count),
              !line.lowercased().contains("http"),
              !line.hasPrefix("#"),
              line.range(of: fieldLabelPrefix, options: [.regularExpression, .caseInsensitive]) == nil,
              line.range(of: #"^@\S"#, options: .regularExpression) == nil,
              !hasPriceMarker(line),
              dateRange(in: line) == nil,
              line.range(of: #"^\d{1,2}:\d{2}\b"#, options: .regularExpression) == nil else {
            return false
        }
        return true
    }

    // MARK: - Shared helpers

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    /// Anchor day used to carry a wall-clock time when the text contains no
    /// recognizable date. Only the hour and minute are meaningful downstream.
    private static var referenceDay: Date {
        calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
    }

    private static func cleanedValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Returns the text after each `label：` occurrence up to the end of the
    /// line, so labeled values win over incidental matches elsewhere.
    private static func labeledLineTails(for label: String, in text: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: "(?:\(label))\\s*:?\\s*([^\n]*)") else { return [] }
        return expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    /// Returns the capture groups of the first match; missing groups are nil.
    private static func firstMatch(
        _ pattern: String,
        in text: String,
        caseInsensitive: Bool = false
    ) -> [String?]? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1 else { return nil }
        return (1..<match.numberOfRanges).map {
            guard let range = Range(match.range(at: $0), in: text) else { return nil }
            return String(text[range])
        }
    }
}
