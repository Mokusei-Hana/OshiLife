import Foundation

struct TicketOption: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var price: Int?
    var description: String?

    init(id: UUID = UUID(), name: String, price: Int? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.description = description
    }
}
