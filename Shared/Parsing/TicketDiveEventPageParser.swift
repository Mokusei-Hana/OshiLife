import Foundation

/// Parses TicketDive event pages (`ticketdive.com`).
///
/// TicketDive lays an event out in labeled blocks: an overview with 公演日時
/// and 会場, a TICKET INFO section that festival pages split into
/// DAY1 / DAY2 / … blocks (each with its own 日時, 開場時刻 / 開演時刻,
/// 会場 and 出演 lineup), and a 詳細 section repeating the announcement in
/// classic form (日程 / 会場 / 開場・開演 / 料金). The parser anchors on
/// these stable semantic labels — never on generated CSS class names — and
/// reads labels rendered either inline (`会場お台場R地区`, `会場: X`) or as a
/// heading with the value on the following line.
///
/// Every field is optional so partial pages still import: unrecognized fields
/// stay nil, and the raw ticket section is preserved as text so ticket
/// options remain editable even when row parsing fails. Notice sections such
/// as 公演に関する注意事項, 入場案内, 禁止事項 and 利用規約 are skipped so
/// their fees and dates never leak into the imported event.
struct TicketDiveEventPageParser: EventPageParsing, Sendable {
    func supports(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        return host == "ticketdive.com" || host == "www.ticketdive.com"
    }

    func parse(html: String, sourceURL: URL) -> EventImportDetails? {
        let openGraph = OpenGraphMetadata(html: html)
        let text = JapaneseEventTextParser.normalize(HTMLTextExtractor.plainText(from: html))
        let lines = Self.eventLines(in: text)

        let firstDayIndex = lines.firstIndex(where: Self.isDayHeader)
        let overviewLines = Array(lines[..<(firstDayIndex ?? lines.endIndex)])
        let dayBlocks = Self.dayBlocks(in: lines, firstDayIndex: firstDayIndex)

        let eventDates = Self.eventDates(overviewLines: overviewLines, allLines: lines, dayBlocks: dayBlocks)
        let times = Self.eventTimes(
            overviewLines: overviewLines,
            dayBlocks: dayBlocks,
            allLines: lines,
            fallbackDay: eventDates?.start
        )
        let venue = Self.labeledLineValue(japanese: #"(?:会場|場所)"#, latin: #"(?:VENUE|PLACE)"#, inLines: lines)
        let performers = Self.performers(inLines: lines)
        let tickets = Self.tickets(inLines: lines, firstDayIndex: firstDayIndex)
        let title = Self.title(openGraph: openGraph, lines: lines, overviewLines: overviewLines)

        guard eventDates != nil || venue != nil || times.open != nil || times.start != nil
            || !tickets.options.isEmpty || !performers.isEmpty else { return nil }

        let scheduleOptions = Self.scheduleOptions(from: dayBlocks)

        return EventImportDetails(
            title: title,
            date: eventDates?.start,
            endDate: eventDates?.end,
            venue: venue,
            openTime: times.open,
            startTime: times.start,
            performers: performers,
            ticketOptions: tickets.options,
            ticketInformation: tickets.information,
            imageURL: Self.coverImageURL(html: html, openGraph: openGraph, sourceURL: sourceURL),
            linkedURL: sourceURL,
            scheduleOptions: scheduleOptions
        )
    }

    // MARK: - Page sectioning

    /// Headers of notice and support sections whose content must not be
    /// mistaken for event data (entrance fees, rule dates, resale prices).
    private static let ignoredSectionHeader = #"^(?:[▼■●◆]\s*|【\s*)?"#
        + #"(?:公演に関する注意事項|申し込みに関する注意事項|注意事項|入場案内|禁止事項|利用規約|免責事項"#
        + #"|よくある質問|FAQ|お問い?合わせ|お問合せ|公演に関するお問合せ|チケットサービスに関する|チケット受け取り方法)"#

    /// Headers that resume event parsing after an ignored notice section.
    private static let resumeSectionHeader =
        #"^(?:DAY\s*\d|TICKET\s*INFO|チケット情報|チケット料金|料金\s*(?::|$)|公演日時|開催日時|公演日|日程|詳細|会場|場所|出演)"#

    /// Labels and section headers that terminate a value spanning lines.
    private static let sectionLabel =
        #"^(?:公演日時|開催日時|公演日|日程|日時|会場|場所|出演者?|料金|チケット|開場|開演|受付|選択する|詳細|※"#
        + #"|DAY\s*\d|(?:TICKET|OPEN|START|VENUE|PLACE)\b)"#

    private static func eventLines(in text: String) -> [String] {
        var result: [String] = []
        var skipping = false
        for line in text.components(separatedBy: .newlines) {
            if line.range(of: ignoredSectionHeader, options: [.regularExpression, .caseInsensitive]) != nil {
                skipping = true
                continue
            }
            if skipping,
               line.range(of: resumeSectionHeader, options: [.regularExpression, .caseInsensitive]) != nil {
                skipping = false
            }
            if !skipping { result.append(line) }
        }
        return result
    }

    private static func isSectionLabel(_ line: String) -> Bool {
        line.range(of: sectionLabel, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Returns the value for a label that TicketDive renders inline — with or
    /// without a colon (`会場お台場R地区`, `会場: X`) — or as a heading
    /// followed by the value on the next line.
    private static func labeledLineValue(
        japanese: String,
        latin: String? = nil,
        inLines lines: [String]
    ) -> String? {
        // Latin labels need a colon or whitespace before the value so that
        // e.g. "ACT" never swallows the start of an unrelated word.
        var inlineLabel = japanese + #"\s*:?"#
        var standaloneLabel = japanese
        if let latin {
            inlineLabel = "(?:" + inlineLabel + "|" + latin + #"\s*(?::|\s)"# + ")"
            standaloneLabel = "(?:" + japanese + "|" + latin + ")"
        }
        let inline = "^" + inlineLabel + #"\s*(\S.*)$"#
        let standalone = "^" + standaloneLabel + #"\s*:?\s*$"#
        for (index, line) in lines.enumerated() {
            if let value = firstCapture(inline, in: line, caseInsensitive: true) {
                return value
            }
            if line.range(of: standalone, options: [.regularExpression, .caseInsensitive]) != nil,
               let next = lines.dropFirst(index + 1).first,
               !isSectionLabel(next), !isDayHeader(next) {
                return next
            }
        }
        return nil
    }

    // MARK: - DAY blocks

    private struct DayBlock {
        /// Human-readable label extracted from the header, e.g. "DAY1".
        var label: String
        /// Block content with the `DAY1` prefix stripped from the header, so
        /// `DAY1日時2026/8/7(金)` contributes its 日時 label like any line.
        var lines: [String]

        var date: Date? {
            if let labeled = TicketDiveEventPageParser.labeledLineValue(
                japanese: #"(?:公演日時|日時)"#,
                inLines: lines
            ), let range = JapaneseEventTextParser.dateRange(in: labeled) {
                return range.start
            }
            return JapaneseEventTextParser.dateRange(in: lines.joined(separator: "\n"))?.start
        }

        var openTime: Date? {
            let clocks = TicketDiveEventPageParser.clockTimes(in: lines.joined(separator: "\n"))
            guard let clock = clocks.open else { return nil }
            return TicketDiveEventPageParser.date(of: clock, on: date ?? TicketDiveEventPageParser.referenceDay)
        }

        var startTime: Date? {
            let clocks = TicketDiveEventPageParser.clockTimes(in: lines.joined(separator: "\n"))
            guard let clock = clocks.start else { return nil }
            return TicketDiveEventPageParser.date(of: clock, on: date ?? TicketDiveEventPageParser.referenceDay)
        }

        var performers: [String] {
            TicketDiveEventPageParser.performers(inLines: lines)
        }
    }

    private static func isDayHeader(_ line: String) -> Bool {
        line.range(of: #"^【?\s*DAY\s*\d+(?!\d)"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Extracts the canonical label (e.g. "DAY1") from a DAY header line.
    private static func dayLabel(from line: String) -> String {
        guard let match = line.range(
            of: #"(?:DAY\s*\d+)"#,
            options: [.regularExpression, .caseInsensitive]
        ) else { return "DAY" }
        return line[match]
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private static func dayBlocks(in lines: [String], firstDayIndex: Int?) -> [DayBlock] {
        guard let firstDayIndex else { return [] }
        var blocks: [DayBlock] = []
        var currentLabel = ""
        var current: [String]?
        for line in lines[firstDayIndex...] {
            if isDayHeader(line) {
                if let finished = current { blocks.append(DayBlock(label: currentLabel, lines: finished)) }
                currentLabel = dayLabel(from: line)
                let remainder = line.replacingOccurrences(
                    of: #"^【?\s*DAY\s*\d+\s*】?\s*"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                current = remainder.isEmpty ? [] : [remainder]
                continue
            }
            // The purchase button ends a day's block; lines between it and
            // the next DAY header belong to no day.
            if line.range(of: #"^選択する"#, options: .regularExpression) != nil {
                if let finished = current { blocks.append(DayBlock(label: currentLabel, lines: finished)) }
                current = nil
                continue
            }
            current?.append(line)
        }
        if let finished = current { blocks.append(DayBlock(label: currentLabel, lines: finished)) }
        return blocks
    }

    // MARK: - Schedule options

    /// Builds selectable schedule options from parsed DAY blocks.
    /// Returns an empty array for single-day events (< 2 blocks) so the
    /// editor shows the day selector only when multiple schedules exist.
    private static func scheduleOptions(from dayBlocks: [DayBlock]) -> [EventScheduleOption] {
        guard dayBlocks.count >= 2 else { return [] }
        return dayBlocks.compactMap { block in
            guard let date = block.date else { return nil }
            return EventScheduleOption(
                dayLabel: block.label,
                date: date,
                openTime: block.openTime,
                startTime: block.startTime,
                performers: block.performers
            )
        }
    }

    // MARK: - Dates

    /// Labels that announce the overall event schedule. The bare 日時 label
    /// is only trusted in the overview because DAY blocks reuse it for their
    /// day-specific dates.
    private static let overallDateLabel = #"(?:公演日時|開催日時|公演日|日程)"#

    private static func eventDates(
        overviewLines: [String],
        allLines: [String],
        dayBlocks: [DayBlock]
    ) -> (start: Date, end: Date?)? {
        if let labeled = labeledLineValue(japanese: #"(?:"# + overallDateLabel + #"|日時)"#, inLines: overviewLines),
           let range = JapaneseEventTextParser.dateRange(in: labeled) {
            return range
        }
        // The 詳細 section repeats the schedule as 日程：… after DAY blocks.
        if let labeled = labeledLineValue(japanese: overallDateLabel, inLines: allLines),
           let range = JapaneseEventTextParser.dateRange(in: labeled) {
            return range
        }
        if let range = JapaneseEventTextParser.dateRange(in: overviewLines.joined(separator: "\n")) {
            return range
        }
        // Pages that only list DAY1 / DAY2 / … blocks: the overall range is
        // the span of the day-specific dates.
        let dayDates = dayBlocks.compactMap(\.date)
        guard let first = dayDates.min() else { return nil }
        let last = dayDates.max() ?? first
        return (first, last > first ? last : nil)
    }

    // MARK: - Times

    private struct ClockTime {
        var hour: Int
        var minute: Int
    }

    private static func eventTimes(
        overviewLines: [String],
        dayBlocks: [DayBlock],
        allLines: [String],
        fallbackDay: Date?
    ) -> (open: Date?, start: Date?) {
        let overview = clockTimes(in: overviewLines.joined(separator: "\n"))
        if overview.open != nil || overview.start != nil {
            return resolved(overview, on: fallbackDay)
        }
        // The first day block that lists times provides the headline
        // OPEN/START; later days stay available in the ticket information.
        for block in dayBlocks {
            let clocks = clockTimes(in: block.lines.joined(separator: "\n"))
            if clocks.open != nil || clocks.start != nil {
                return resolved(clocks, on: block.date ?? fallbackDay)
            }
        }
        // Fall back to the 詳細 section's 開場 / 開演：… announcement line.
        let fallback = clockTimes(in: allLines.joined(separator: "\n"))
        return resolved(fallback, on: fallbackDay)
    }

    private static func clockTimes(in text: String) -> (open: ClockTime?, start: ClockTime?) {
        let time = #"(\d{1,2}):(\d{2})"#
        let combined = #"(?:開場|OPEN)\s*/\s*(?:開演|START)\s*:?\s*"# + time + #"\s*/\s*"# + time
        if let values = captures(combined, in: text, count: 4, caseInsensitive: true),
           let open = clock(hour: values[0], minute: values[1]),
           let start = clock(hour: values[2], minute: values[3]) {
            return (open, start)
        }
        let open = firstClock(#"(?:開場(?:時刻|時間)?|OPEN)\s*:?\s*"# + time, in: text)
        let start = firstClock(#"(?:開演(?:時刻|時間)?|START)\s*:?\s*"# + time, in: text)
        return (open, start)
    }

    private static func firstClock(_ pattern: String, in text: String) -> ClockTime? {
        guard let values = captures(pattern, in: text, count: 2, caseInsensitive: true) else { return nil }
        return clock(hour: values[0], minute: values[1])
    }

    private static func clock(hour: String, minute: String) -> ClockTime? {
        guard let hour = Int(hour), let minute = Int(minute),
              (0...29).contains(hour), (0...59).contains(minute) else { return nil }
        return ClockTime(hour: hour, minute: minute)
    }

    private static func resolved(
        _ clocks: (open: ClockTime?, start: ClockTime?),
        on day: Date?
    ) -> (open: Date?, start: Date?) {
        let anchor = day ?? referenceDay
        return (date(of: clocks.open, on: anchor), date(of: clocks.start, on: anchor))
    }

    private static func date(of clock: ClockTime?, on day: Date) -> Date? {
        guard let clock else { return nil }
        // Late-night listings such as 25:00 mean 1:00 on the following day.
        let dayOffset = clock.hour / 24
        let anchor = dayOffset > 0 ? calendar.date(byAdding: .day, value: dayOffset, to: day) ?? day : day
        return calendar.date(bySettingHour: clock.hour % 24, minute: clock.minute, second: 0, of: anchor)
    }

    // MARK: - Performers

    /// Separators between lineup entries. Restricted to slashes because
    /// TicketDive renders one performer per line with a trailing slash, and
    /// names routinely contain commas and interpuncts (e.g. Mirror,Mirror).
    private static let performerSeparators = CharacterSet(charactersIn: "/／")

    private static func performers(inLines lines: [String]) -> [String] {
        let japanese = #"出演者?"#
        let latin = #"(?:LINE\s*UP|LINEUP|ACT)"#
        let inline = #"^(?:"# + japanese + #"\s*:?|"# + latin + #"\s*(?::|\s))\s*(\S.*)$"#
        let standalone = #"^(?:"# + japanese + "|" + latin + #")\s*:?\s*$"#
        for (index, line) in lines.enumerated() {
            if let value = firstCapture(inline, in: line, caseInsensitive: true) {
                let names = collectNames(startingWith: value, continuingFrom: index + 1, in: lines)
                if !names.isEmpty { return names }
            }
            if line.range(of: standalone, options: [.regularExpression, .caseInsensitive]) != nil {
                let names = collectNames(startingWith: nil, continuingFrom: index + 1, in: lines)
                if !names.isEmpty { return names }
            }
        }
        return []
    }

    /// Gathers a lineup that spans lines: each entry ends with a slash and
    /// the final entry has none, which closes the list.
    private static func collectNames(startingWith value: String?, continuingFrom index: Int, in lines: [String]) -> [String] {
        var chunks: [String] = []
        var expectMore = true
        if let value {
            chunks.append(value)
            expectMore = endsWithSeparator(value)
        }
        for line in lines.dropFirst(index).prefix(320) where expectMore {
            if isSectionLabel(line) || isDayHeader(line) { break }
            chunks.append(line)
            expectMore = endsWithSeparator(line)
        }
        return chunks
            .flatMap { $0.components(separatedBy: performerSeparators) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(300)
            .map { $0 }
    }

    private static func endsWithSeparator(_ line: String) -> Bool {
        guard let scalar = line.trimmingCharacters(in: .whitespaces).unicodeScalars.last else { return false }
        return performerSeparators.contains(scalar)
    }

    // MARK: - Tickets

    private static let ticketSectionHeader = #"^(?:[▼■●◆]\s*|【\s*)?"#
        + #"(?:TICKET\s*INFO(?:RMATION)?|チケット情報|チケット料金|チケット販売|料金\s*(?::|$))"#

    private static let priceLabeledLine = #"^(?:チケット)?料金\s*:?\s*(\S.*)$"#

    private static func tickets(
        inLines lines: [String],
        firstDayIndex: Int?
    ) -> (options: [TicketOption], information: String?) {
        let headerIndex = lines.firstIndex {
            $0.range(of: ticketSectionHeader, options: [.regularExpression, .caseInsensitive]) != nil
        }
        let sectionStart: Int? = switch (headerIndex, firstDayIndex) {
        case let (.some(header), .some(day)): min(header, day)
        case let (.some(header), nil): header
        case let (nil, day): day
        }
        let scope = sectionStart.map { Array(lines[$0...]) } ?? lines
        // Day dates and times only count as ticket context inside an actual
        // ticket section; without one they are plain event fields.
        let collectContext = sectionStart != nil

        var options: [TicketOption] = []
        var informationLines: [String] = []
        var seen = Set<String>()

        func append(_ option: TicketOption) {
            guard options.count < 30 else { return }
            // DAY blocks repeat the same rows; keep each name/price pair once.
            if seen.insert("\(option.name)|\(option.price ?? -1)").inserted {
                options.append(option)
            }
        }

        for line in scope {
            if isDayHeader(line) || line.range(of: #"^(?:公演日時|日時)"#, options: .regularExpression) != nil {
                if collectContext { informationLines.append(line) }
                continue
            }
            if line.range(of: #"(?:開場|開演|OPEN|START)[^\n]*\d{1,2}:\d{2}"#,
                          options: [.regularExpression, .caseInsensitive]) != nil {
                if collectContext { informationLines.append(line) }
                continue
            }
            if line.range(of: #"^※"#, options: .regularExpression) != nil {
                // Notes such as "※通し券なし/各税込" belong to the ticket
                // block once tickets were found.
                if !options.isEmpty { informationLines.append(line) }
                continue
            }
            if let content = firstCapture(priceLabeledLine, in: line) {
                ticketOptions(fromContent: content).forEach(append)
                informationLines.append(line)
                continue
            }
            if let option = ticketOption(from: line) {
                append(option)
                informationLines.append(line)
                continue
            }
            if collectContext, JapaneseEventTextParser.dateRange(in: line) != nil {
                informationLines.append(line)
            }
        }

        // The raw section text survives even when no row parsed, so ticket
        // options stay editable from the imported notes.
        if informationLines.isEmpty, sectionStart != nil {
            informationLines = Array(scope.prefix(40))
        }
        let information = informationLines.prefix(40).joined(separator: "\n")
        return (options, information.isEmpty ? nil : information)
    }

    /// Parses a price listing that may contain several options separated by
    /// slashes, e.g. `VIPチケット ¥28,000 / 一般¥5,000- / 女性¥4,000-`. A
    /// single-option listing is kept whole so slashes inside descriptions
    /// survive.
    private static func ticketOptions(fromContent content: String) -> [TicketOption] {
        let segments = priceMarkerCount(in: content) > 1
            ? content.components(separatedBy: CharacterSet(charactersIn: "/|"))
            : [content]
        return segments.compactMap(ticketOption(from:))
    }

    private static func priceMarkerCount(in line: String) -> Int {
        let yenSigns = line.filter { $0 == "¥" }.count
        guard let expression = try? NSRegularExpression(pattern: #"\d\s*円"#) else { return yenSigns }
        return yenSigns + expression.numberOfMatches(in: line, range: NSRange(line.startIndex..., in: line))
    }

    private static func ticketOption(from line: String) -> TicketOption? {
        guard line.range(of: #"^[※•]"#, options: .regularExpression) == nil else { return nil }
        let patterns = [
            #"^(.*?)\s*¥\s*([0-9][0-9,]{0,9})\s*円?\s*[-−ー]?\s*(.*)$"#,
            #"^(.*?)\s*(?<![,\d])([0-9][0-9,]{0,9})\s*円\s*[-−ー]?\s*(.*)$"#
        ]
        for pattern in patterns {
            guard let values = captures(pattern, in: line, count: 3),
                  let price = Int(values[1].replacingOccurrences(of: ",", with: "")) else { continue }
            var name = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
            name = name.trimmingCharacters(in: CharacterSet(charactersIn: ":・…"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count <= 30 else { return nil }
            if name.isEmpty { name = "チケット" }
            let description = values[2].trimmingCharacters(in: .whitespacesAndNewlines)
            return TicketOption(name: name, price: price, description: description.isEmpty ? nil : description)
        }
        return nil
    }

    // MARK: - Title

    private static func title(openGraph: OpenGraphMetadata, lines: [String], overviewLines: [String]) -> String? {
        // og:title carries the event name with a "| TicketDive" suffix that
        // cleanedTitle strips via og:site_name.
        if let cleaned = openGraph.cleanedTitle, cleaned != openGraph.siteName {
            return cleaned
        }
        // The 詳細 section quotes the announcement title.
        if let quoted = firstCapture(#"『([^』\n]{1,80})』"#, in: lines.joined(separator: "\n")) {
            return quoted
        }
        if let quoted = firstCapture(#"「([^」\n]{1,80})」"#, in: lines.joined(separator: "\n")) {
            return quoted
        }
        for line in overviewLines.prefix(6) where isLikelyTitle(line) {
            return line
        }
        return nil
    }

    private static func isLikelyTitle(_ line: String) -> Bool {
        (2...80).contains(line.count)
            && !line.lowercased().contains("http")
            && line.range(of: #"TicketDive|ログイン|主催者"#, options: [.regularExpression, .caseInsensitive]) == nil
            && !isSectionLabel(line)
            && line.range(of: #"¥|\d\s*円"#, options: .regularExpression) == nil
            && JapaneseEventTextParser.dateRange(in: line) == nil
    }

    // MARK: - Cover image

    private static func coverImageURL(html: String, openGraph: OpenGraphMetadata, sourceURL: URL) -> URL? {
        // The page's embedded event data carries the real cover under the
        // stable topImage key; og:image is TicketDive's generic site logo.
        if let topImage = firstCapture(#""topImage"\s*:\s*"(https?:[^"]+)""#, in: html),
           let url = URL(string: topImage.replacingOccurrences(of: #"\/"#, with: "/")) {
            return url
        }
        return openGraph.imageURLString.flatMap { URL(string: $0, relativeTo: sourceURL)?.absoluteURL }
    }

    // MARK: - Shared helpers

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    /// Anchor day used to carry a wall-clock time when the page contains no
    /// recognizable date. Only the hour and minute are meaningful downstream.
    private static var referenceDay: Date {
        calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
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
        var values: [String] = []
        for index in 1...count {
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            values.append(String(text[range]))
        }
        return values
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
