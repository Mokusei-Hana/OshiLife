import Foundation

/// Shared HTML helpers for parsers that read arbitrary event pages.
enum HTMLTextExtractor {
    /// Converts an HTML document into trimmed plain-text lines suitable for
    /// `JapaneseEventTextParser`.
    static func plainText(from html: String) -> String {
        let text = html
            .replacingOccurrences(of: #"(?is)<(script|style)\b[^>]*>.*?</\1>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)</(?:p|div|h[1-6]|li|tr|td|th|dt|dd|section|article)>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return decodeEntities(text)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Decodes the named and numeric HTML entities that commonly appear in
    /// event pages and metadata attributes.
    static func decodeEntities(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        result = replacingNumericEntities(in: result)
        return result.replacingOccurrences(of: "&amp;", with: "&")
    }

    private static func replacingNumericEntities(in text: String) -> String {
        guard text.contains("&#"),
              let expression = try? NSRegularExpression(pattern: "&#(x[0-9a-fA-F]{1,6}|[0-9]{1,7});") else {
            return text
        }
        var result = text
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let range = Range(match.range, in: result),
                  let valueRange = Range(match.range(at: 1), in: result) else { continue }
            let value = result[valueRange]
            let codePoint: UInt32?
            if value.hasPrefix("x") {
                codePoint = UInt32(value.dropFirst(), radix: 16)
            } else {
                codePoint = UInt32(value)
            }
            guard let codePoint, let scalar = Unicode.Scalar(codePoint) else { continue }
            result.replaceSubrange(range, with: String(Character(scalar)))
        }
        return result
    }
}
