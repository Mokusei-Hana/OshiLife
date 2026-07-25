import Foundation

enum TicketPlatform: String, CaseIterable, Sendable {
    case ePlus
    case ticketPia
    case lawsonTicket
    case livePocket
    case tiget
    case zaiko

    var ticketAccessURL: URL {
        switch self {
        case .ePlus:
            URL(string: "https://eplus.jp/jyoukyou/")!
        case .ticketPia:
            URL(string: "https://ticket-account.pia.jp/pia/digipoke/list.do")!
        case .lawsonTicket:
            URL(string: "https://l-tike.com/mypage/")!
        case .livePocket:
            URL(string: "https://t.livepocket.jp/my_ticket")!
        case .tiget:
            URL(string: "https://tiget.net/users/sign_in")!
        case .zaiko:
            URL(string: "https://zaiko.io/account/eticket")!
        }
    }

    static func detect(from purchaseURL: URL) -> TicketPlatform? {
        guard let host = purchaseURL.host(percentEncoded: false)?.lowercased() else {
            return nil
        }

        return allCases.first { platform in
            platform.hosts.contains { host == $0 || host.hasSuffix(".\($0)") }
        }
    }

    private var hosts: [String] {
        switch self {
        case .ePlus:
            ["eplus.jp"]
        case .ticketPia:
            ["pia.jp"]
        case .lawsonTicket:
            ["l-tike.com"]
        case .livePocket:
            ["livepocket.jp"]
        case .tiget:
            ["tiget.net"]
        case .zaiko:
            ["zaiko.io"]
        }
    }
}
