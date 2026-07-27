# OshiLife — Platform Parity Matrix

**Governance rule:** when any feature changes on one platform, open a parity
issue/PR for the other. Use this document as the checklist — update it in the
same PR as the feature change.

Legend: ✅ shipped · ⚠️ gap (documented) · ❌ missing · 🚫 N/A (platform-specific)

---

## Core Data

| Feature | iOS | Android | Notes |
|---|---|---|---|
| `LiveEvent` schema (V3 / Drift schema 1) | ✅ | ✅ | Uppercase UUIDs, ISO-8601 UTC dates, relative image paths |
| `TicketOption` JSON codec (round-trip) | ✅ | ✅ | Null fields omitted; `id` uppercase |
| `LiveStatus` enum + unknown → `planned` fallback | ✅ | ✅ | |
| `AppSettings` with same preference keys | ✅ | ✅ | Same keys and raw values; iOS legacy `eventDisplayMode` key not ported to Android (no legacy installs) |
| Custom accent color default `#C84EF0` | ✅ | ✅ | |
| 9 `OshiColor` seed colors | ✅ | ✅ | |
| Appearance setting (system / light / dark) | ✅ | ✅ | |
| Language setting | ✅ (persisted, not applied) | ✅ (applied via `MaterialApp.locale`) | iOS gap: language picker is a no-op. Fix on both platforms together. |
| Home display style (card / list) | ✅ | ✅ | |

---

## Sort and Query

| Feature | iOS | Android | Notes |
|---|---|---|---|
| `fetchAll` two-block sort (upcoming asc, past desc) | ✅ | ✅ | Same `startOfDay` pivot via device calendar |
| Upcoming query (planned, future, asc) | ✅ | ✅ | |
| Historical query (attended, desc) | ✅ | ✅ | |
| Status never derived from dates | ✅ | ✅ | Manual user state only |

---

## Import Pipeline (parity contract §6.1)

| Feature | iOS | Android | Notes |
|---|---|---|---|
| X URL validation + normalization | ✅ | ✅ | All accept/reject table cases tested |
| oEmbed text extraction (HTML→plain) | ✅ | ✅ | `&amp;`, `<br>`, anchor text, no-`<p>` → null |
| FxTwitter media client (first photo wins) | ✅ | ✅ | |
| Remote image download (25 MiB cap) | ✅ | ✅ | |
| Draft builder ordering + warning/silence contract | ✅ | ✅ | |
| heroines.jp parser (5 fixtures) | ✅ | ✅ | JST-anchored; nil on non-event |
| EventLinkImporter + EUC-JP fallback | ✅ | ✅ | |
| TicketPlatform host matching + `ticketActionURL` | ✅ | ✅ | Dot-anchored suffix |
| Performers split on `/ ／ 、 ,` | ✅ | ✅ | |
| Retry fills only empty fields | ✅ | ✅ | |
| Duplicate detection by exact `sourceURLString` | ✅ | ✅ | Advisory banner; duplicates still saveable |

---

## Image Store

| Feature | iOS | Android | Notes |
|---|---|---|---|
| ≤ 2400 px longest edge, JPEG q0.85 | ✅ | ✅ | |
| Relative path `Images/<UUID>.jpg` | ✅ | ✅ | Uppercase UUID |
| Replace-after-save / rollback-on-failure | ✅ | ✅ | |
| Delete with event (orphan cleanup) | ✅ | ✅ | |

---

## Screens

| Screen | iOS | Android | Notes |
|---|---|---|---|
| Home — card dashboard + hero carousel | ✅ | ✅ | |
| Home — list mode with relative times | ✅ | ✅ | |
| Home — status filter | ✅ | ✅ | |
| Home — empty state | ✅ | ✅ | |
| Home — startup-warning banner (persistence fallback) | ✅ | ✅ | |
| Detail — all sections (cover, info, performers, tickets, notes, links) | ✅ | ✅ | |
| Detail — SelectableText on title and notes | ✅ | ✅ | |
| Detail — ticket platform-aware action link | ✅ | ✅ | |
| Editor — all fields including optional dates | ✅ | ✅ | |
| Editor — duplicate / import warning banners | ✅ | ✅ | |
| Editor — inline URL validation | ✅ | ✅ | |
| Editor — validation summary | ✅ | ✅ | |
| Editor — cover image picker | ✅ | ✅ | |
| Ticket entry (half-sheet) | ✅ | ✅ | |
| Manual X import | ✅ | ✅ | Clipboard suggestion |
| Import editor | ✅ | ✅ | |
| Settings — all options | ✅ | ✅ | |
| Venue picker | ✅ (MKLocalSearch) | ⚠️ Manual entry only (Option A, §7.5) | Android has no free native equivalent; service interface is ready for Places/Nominatim |

---

## Maps (§7.4)

| Feature | iOS | Android | Notes |
|---|---|---|---|
| Google Maps URL launch | ✅ | ✅ | Same `https://www.google.com/maps/search/` URL |
| Apple Maps launch | ✅ | 🚫 N/A | Apple Maps not on Android |
| Generic `geo:` system chooser | 🚫 N/A | ✅ | Replaces Apple Maps for Android |
| Error dialog on launch failure | ✅ | ✅ | |
| Bottom sheet with both options | ✅ | ✅ | |

---

## Share / Import Entry Points

| Feature | iOS | Android | Notes |
|---|---|---|---|
| X Share Extension (App Group staging) | ✅ | 🚫 N/A | Android uses share intents instead |
| `oshilife://import/<UUID>` deep link | ✅ | 🚫 N/A | No URL scheme queue needed on Android |
| `ACTION_SEND` share intent receive | 🚫 N/A | ✅ | Kotlin shim → `ShareReceiveCoordinator` |
| Cold-start intent buffering | ✅ (queue drain) | ✅ (initial-intent pattern) | Android buffers until Dart ready |
| Import editor after share (PopScope-guarded) | ✅ | ✅ | |

---

## Accessibility

| Feature | iOS | Android | Notes |
|---|---|---|---|
| Combined `Semantics` on list/card items | ✅ | ✅ | `card.accessibility` label format |
| Accessibility identifiers / `Semantics(identifier:)` | ✅ | ✅ | Used as widget keys in tests |
| Minimum tap target 44 pt / 44 dp | ✅ | ✅ | |
| Venue map button semantic hint | ✅ | ✅ | |

---

## Localization

| Feature | iOS | Android | Notes |
|---|---|---|---|
| Japanese (source / primary) | ✅ | ✅ | |
| Simplified Chinese | ✅ | ✅ | |
| English | ❌ | ❌ | Product decision: no English in v1 (§13.3) |
| `¥` glyph hardcoded (JPY-only) | ✅ | ✅ | Product decision, change on both platforms |
| Countdown suffixes `d/h/m` ASCII | ✅ | ✅ | Parity over polish; localize on both together (§13.4) |
| Android 13 per-app language (`localeConfig`) | 🚫 N/A | ✅ | |

---

## CI / CD

| Feature | iOS | Android | Notes |
|---|---|---|---|
| Simulator build + tests on macOS runner | ✅ | 🚫 N/A | |
| Unsigned IPA artifact | ✅ | 🚫 N/A | |
| `flutter analyze` + `flutter test` on Linux runner | 🚫 N/A | ✅ | |
| Debug-signed release APK artifact | 🚫 N/A | ✅ | |
| Path filters (Flutter changes don't trigger iOS CI) | ✅ | ✅ | `paths-ignore` on both iOS workflows (§10.3) |

---

## Known Gaps and Open Decisions

| # | Gap | iOS | Android | Tracking |
|---|---|---|---|---|
| G1 | Language setting actually applied at runtime | ⚠️ No-op (known gap) | ✅ Fixed | Fix iOS together with any future language-setting UX change |
| G2 | Venue autocomplete / search | ✅ MKLocalSearch | ⚠️ Manual entry only | Android Option A until Places/Nominatim decision |
| G3 | JST rendering shift for overseas users | ⚠️ | ⚠️ | Fix on both platforms simultaneously (§4.3) |
| G4 | Countdown suffix localization | ⚠️ ASCII | ⚠️ ASCII | Change on both platforms together |
| G5 | App icon (brand asset) | ❌ No icon yet | ⚠️ Placeholder (music note on #C84EF0) | Shared brand task; replace PNGs + iOS asset catalog together |
| G6 | Export / import format (`oshilife-export-v1`) | ❌ | ❌ | Deferred to post-v1.1 (§4.2, §13.6) |
| G7 | iPad-optimized layout | ✅ | ⚠️ Phone layout (responsive enough) | Android tablets get phone layout in v1 |
| G8 | Real `applicationId` / Play Console | — | ⚠️ Placeholder `com.example.oshilife` | Replace in signing + Play prep PR |

---

*Last updated: M5 — Polish + Release preparation (v1.1.0)*
