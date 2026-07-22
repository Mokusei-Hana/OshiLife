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
              segments[2].allSatisfy(\.isNumber) else {
            return nil
        }

        components.scheme = "https"
        components.host = "x.com"
        components.path = "/\(segments[0])/status/\(segments[2])"
        components.query = nil
        components.fragment = nil
        return components.url
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
