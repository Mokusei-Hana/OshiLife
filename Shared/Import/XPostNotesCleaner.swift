import Foundation

/// Removes URL noise from imported X post text before it becomes Notes.
///
/// Two kinds of noise are dropped: media attachment placeholders such as
/// `pic.twitter.com/…` (which are not links to anything importable), and
/// URLs that are already stored in a structured field — the X source URL,
/// the event or ticket link, and the shortened `t.co` URLs that redirected
/// to it. Announcement prose, hashtags, mentions and warnings are kept.
enum XPostNotesCleaner {
    private static let mediaPlaceholderPattern =
        #"(?:https?://)?pic\.(?:twitter|x)\.com/\S+"#

    static func cleanedNotes(_ text: String, removing storedURLs: [URL] = []) -> String {
        var cleaned = text.replacingOccurrences(
            of: mediaPlaceholderPattern,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        for variant in removalVariants(of: storedURLs) {
            cleaned = cleaned.replacingOccurrences(of: variant, with: "")
        }
        return normalizedWhitespace(cleaned)
    }

    /// Absolute strings plus their scheme-less renderings, longest first so a
    /// full URL never leaves its own scheme-less remainder behind.
    private static func removalVariants(of urls: [URL]) -> [String] {
        var variants: Set<String> = []
        for url in urls {
            let absolute = url.absoluteString
            variants.insert(absolute)
            for scheme in ["https://", "http://"] where absolute.lowercased().hasPrefix(scheme) {
                variants.insert(String(absolute.dropFirst(scheme.count)))
            }
        }
        return variants.sorted { $0.count > $1.count }
    }

    private static func normalizedWhitespace(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map {
                $0.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            }
        var result: [String] = []
        var previousEmpty = false
        for line in lines {
            if line.isEmpty {
                if !previousEmpty { result.append(line) }
                previousEmpty = true
            } else {
                result.append(line)
                previousEmpty = false
            }
        }
        return result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
