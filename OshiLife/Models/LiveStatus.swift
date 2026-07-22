import Foundation
import SwiftUI

enum LiveStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case planned
    case attended
    case cancelled

    var id: String { rawValue }

    var localizedName: LocalizedStringResource {
        switch self {
        case .planned: "status.planned"
        case .attended: "status.attended"
        case .cancelled: "status.cancelled"
        }
    }

    var systemImage: String {
        switch self {
        case .planned: "sparkles"
        case .attended: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .planned: .pink
        case .attended: .green
        case .cancelled: .secondary
        }
    }
}
