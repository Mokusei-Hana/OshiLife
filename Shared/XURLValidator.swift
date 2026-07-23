import Foundation

enum XURLValidator {
    private static let allowedHosts = ["x.com", "www.x.com", "twitter.com", "www.twitter.com", "mobile.twitter.com"]

    static func normalizedPostURL(from candidate: URL) -> URL? {
        guard var components = URLComponents(url: candidate, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              allowedHosts.contains(host) else {
            return nil
        }

        let segments = components.path.split(separator: "/")
        guard segments.count >= 3,
              segments[1].lowercased() == "status",
              !segments[0].isEmpty,
              segments[2].allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }

        components.scheme = "https"
        components.host = "x.com"
        components.user = nil
        components.password = nil
        components.port = nil
        components.path = "/\(segments[0])/status/\(segments[2])"
        components.query = nil
        components.fragment = nil
        return components.url
    }

    static func normalizedPostURL(from text: String) -> URL? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let candidate = URL(string: value) else { return nil }
        return normalizedPostURL(from: candidate)
    }

    static func firstPostURL(in text: String) -> URL? {
        guard let expression = try? NSRegularExpression(
            pattern: #"https://[^\s<>\"']+"#,
            options: [.caseInsensitive]
        ) else { return nil }
        let trailingPunctuation = CharacterSet(charactersIn: ",.!?;:、。)]}")
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text) else { continue }
            let rawValue = String(text[range]).trimmingCharacters(in: trailingPunctuation)
            if let candidate = URL(string: rawValue), let normalized = normalizedPostURL(from: candidate) {
                return normalized
            }
        }
        return nil
    }
}
