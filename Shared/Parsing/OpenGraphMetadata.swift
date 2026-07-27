import Foundation

/// Open Graph metadata found in a webpage's `<meta>` tags.
struct OpenGraphMetadata: Sendable {
    var title: String?
    var siteName: String?
    var description: String?
    var imageURLString: String?

    init(html: String) {
        title = Self.content(for: "og:title", in: html)
        siteName = Self.content(for: "og:site_name", in: html)
        description = Self.content(for: "og:description", in: html)
        imageURLString = Self.content(for: "og:image", in: html)
            ?? Self.content(for: "twitter:image", in: html)
    }

    /// The og:title with a trailing "| Site Name" style suffix removed.
    var cleanedTitle: String? {
        guard var title else { return nil }
        if let siteName, !siteName.isEmpty, title != siteName,
           let range = title.range(of: siteName, options: .backwards),
           range.upperBound == title.endIndex {
            title = String(title[..<range.lowerBound])
                .trimmingCharacters(in: CharacterSet(charactersIn: " \t|｜/／・:：–—−-"))
        }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func content(for property: String, in html: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            #"(?is)<meta[^>]*(?:property|name)\s*=\s*["']"# + escaped + #"["'][^>]*content\s*=\s*["']([^"']*)["']"#,
            #"(?is)<meta[^>]*content\s*=\s*["']([^"']*)["'][^>]*(?:property|name)\s*=\s*["']"# + escaped + #"["']"#
        ]
        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern),
                  let match = expression.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html) else { continue }
            let value = HTMLTextExtractor.decodeEntities(String(html[range]))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { return value }
        }
        return nil
    }
}
