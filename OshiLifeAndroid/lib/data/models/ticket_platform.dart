/// Port of `Shared/Models/TicketPlatform.swift`.
///
/// Detection is dot-anchored host matching: `host == h` or
/// `host.endsWith('.' + h)` — so `eplus.jp.example.com` must NOT match.
enum TicketPlatform {
  ePlus,
  ticketPia,
  lawsonTicket,
  livePocket,
  tiget,
  zaiko;

  Uri get ticketAccessUrl => switch (this) {
    ePlus => Uri.parse('https://eplus.jp/jyoukyou/'),
    ticketPia => Uri.parse(
      'https://ticket-account.pia.jp/pia/digipoke/list.do',
    ),
    lawsonTicket => Uri.parse('https://l-tike.com/mypage/'),
    livePocket => Uri.parse('https://t.livepocket.jp/my_ticket'),
    tiget => Uri.parse('https://tiget.net/users/sign_in'),
    zaiko => Uri.parse('https://zaiko.io/account/eticket'),
  };

  List<String> get _hosts => switch (this) {
    ePlus => const ['eplus.jp'],
    ticketPia => const ['pia.jp'],
    lawsonTicket => const ['l-tike.com'],
    livePocket => const ['livepocket.jp'],
    tiget => const ['tiget.net'],
    zaiko => const ['zaiko.io'],
  };

  static TicketPlatform? detect(Uri purchaseUrl) {
    final host = purchaseUrl.host.toLowerCase();
    if (host.isEmpty) return null;
    for (final platform in values) {
      for (final candidate in platform._hosts) {
        if (host == candidate || host.endsWith('.$candidate')) {
          return platform;
        }
      }
    }
    return null;
  }
}
