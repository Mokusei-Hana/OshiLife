# OshiLife — Flutter Android Plan

**Status: planning only. No Flutter code exists yet.**

## 0. Scope and non-goals

This is **not a migration of the iOS app**. The final architecture is:

| Platform | App | Status |
|---|---|---|
| iOS | Existing SwiftUI + SwiftData app (`OshiLife/`, `Shared/`, `ShareExtension/`) | **Unchanged.** Remains the reference implementation. |
| Android | New Flutter app (this plan) | Built from scratch, mirroring the iOS app's features and design language. |

Both apps are maintained separately in this repository with **feature parity** as the ongoing goal. The iOS codebase, its Xcode project, and its CI workflows are not modified by this effort, with one narrowly-scoped exception proposed in §10.3 (path filters so Flutter commits don't trigger macOS runners — additive, does not change iOS builds themselves).

Inherited product non-goals (from `IMPLEMENTATION_PLAN.md`): no backend, no accounts, no cloud sync, no AI parsing, no OCR, no social features, no X API, no X page scraping. Everything is local, single-user data.

---

## 1. Current iOS app — analysis summary

Facts below were verified against branch `feature/flutter-android` @ `d068a9b` (identical to `agent/ios-ci`). ~4,760 LOC production Swift across 52 files, **zero third-party dependencies**, iOS 26.0 minimum, Swift 6 strict concurrency, iPhone + iPad.

### 1.1 Architecture

- Pattern: simple MVVM. Five `@MainActor @Observable` classes (`LiveListViewModel`, `LiveEditorViewModel`, `ManualXImportViewModel`, `PendingImportCoordinator`, `VenueSearchService`); no `ObservableObject`, no `@AppStorage`, no `@Query` — all data flows through a hand-rolled `LiveStore`.
- Layout: `OshiLife/App` (entry), `OshiLife/Features/{Home,LiveDetail,LiveEditor,Import,Settings}`, `OshiLife/Core/{DesignSystem,Utilities}`, `OshiLife/Data/{Models,Persistence}`, `OshiLife/Services`; `Shared/` (compiled into app **and** Share Extension): `Models`, `Import`, `Parsing`, `Networking`, `Resources`.
- Composition root: `RootView` builds `LiveStore`, `ImageStore`, `PendingImportStore`, owns `AppSettings`, and injects the theme via a single `.tint(palette.primary)` + `.preferredColorScheme`.

### 1.2 Data model (SwiftData)

One persisted entity. Schema is versioned V1→V2→V3 (lightweight migrations); **V3 is current**. Store lives in the App Group container (`group.com.example.OshiLife`), database name `OshiLife`, CloudKit disabled, autosave disabled (explicit saves only).

`LiveEvent` (V3) — flat, no relationships, unique index on `id` only:

| # | Property | Type | Notes |
|---|---|---|---|
| 1 | `id` | `UUID` | `@Attribute(.unique)` |
| 2 | `artistName` | `String` | required |
| 3 | `title` | `String` | required |
| 4 | `eventDate` | `Date` | required, absolute instant |
| 5 | `openTime` | `Date?` | time-of-day picker; day component may disagree with `eventDate` (see §6.2) |
| 6 | `startTime` | `Date?` | same caveat |
| 7 | `venue` | `String` | default `""` |
| 8 | `address` | `String` | default `""` |
| 9 | `latitude` | `Double?` | |
| 10 | `longitude` | `Double?` | |
| 11 | `coverImagePath` | `String?` | **relative** path, e.g. `Images/<UUID>.jpg` |
| 12 | `ticketURLString` | `String` | `""` = absent |
| 13 | `sourceURLString` | `String` | `""` = absent; dedup key for imports |
| 14 | `performersJSON` | `String` | JSON array of strings, default `"[]"` |
| 15 | `ticketOptionsJSON` | `String` | JSON array of `TicketOption`, default `"[]"` |
| 16 | `selectedTicketID` | `UUID?` | integrity enforced in code only: setter of `ticketOptions` nils it when the selected option disappears |
| 17 | `notes` | `String` | default `""` |
| 18 | `statusRawValue` | `String` | `planned` / `attended` / `cancelled`; unknown → `planned` |
| 19 | `createdAt` | `Date` | set at init |
| 20 | `updatedAt` | `Date` | set manually on every save |

Value types: `TicketOption { id: UUID, name: String, price: Int? (JPY), description: String? }`, `LiveStatus` enum, `VenueSelection` (transient), `TicketPlatform` (host-detection enum, §1.5), `PendingShareImport` + `EventImportDetails` (import DTOs).

Key behaviors to replicate:

- **Sort order** (`LiveStore.fetchAll`): pivot = `startOfDay(now)` in device calendar; upcoming (`eventDate >= today`) first ascending, then past descending.
- Dashboard queries: upcoming = `status == planned && eventDate > now` ascending; history = `status == attended` descending.
- **Status is never derived from dates** — purely manual user state.
- `ticketActionURL`: no ticket selected → raw purchase URL; ticket selected → `TicketPlatform.detect(host)` deep link to the vendor's "my tickets" page, falling back to the purchase URL.
- URL validation `validHTTPURL`: trim, parse, scheme ∈ {http, https}, non-nil host; empty string is valid "absent".
- `updatedAt` maintained by hand; all strings trimmed on save; performers text split on `/ ／ 、 ,`.

Settings (`AppSettings`) are **plain `UserDefaults`** (not App Group), write-through `didSet`:

| Key | Type | Values / default |
|---|---|---|
| `settings.accentColorMode` | String | `oshiLifeDefault` (default) / `oshiColor` / `custom` |
| `settings.appearance` | String | `system` (default) / `light` / `dark` |
| `settings.customAccentColor` | JSON Data | RGBA doubles; default (0.784, 0.306, 0.941, 1) ≈ `#C84EF0` |
| `settings.oshiColor` | String | 9 cases, default `purple` |
| `settings.homeDisplayStyle` | String | `card` (default) / `list`; falls back to legacy key `eventDisplayMode` |
| `settings.language` | String | `system` / `japanese` / `simplifiedChinese` — **persisted but never applied on iOS** (known gap) |

### 1.3 Views and navigation

Single `NavigationStack` rooted at `LiveListView` with a typed `[UUID]` path; everything else is modal:

- Push: `LiveDetailView` via `navigationDestination(for: UUID.self)` (deleted-event fallback view); `SettingsView` via boolean destination.
- Sheets: editor (`sheet(item:)` with create/edit payload), manual X import, import editor (`interactiveDismissDisabled`), venue picker (sheet-on-sheet), ticket entry (`.medium` detent). Serialized sheet handoff: manual import closes → `onDismiss` opens the import editor (iOS one-sheet limit).
- Deep link: `oshilife://import/<UUID>` via `onOpenURL`, plus queue polling on launch/foreground.

Screens: Home (card dashboard with hero carousel + countdown + attended shelf, or list mode with relative times; 60 s `TimelineView` tickers; status filter menu; add menu), Detail (sectioned cards: hero cover, info with OPEN/START, venue button → Apple/Google Maps dialog, performers, tickets with selected highlight + platform-aware action link, notes, links), Editor (form: duplicate/import warning banners, cover PhotosPicker, basic fields, optional-date pattern, toggle-gated times, venue picker, ticket list with swipe-delete + half-sheet add, URL fields with inline validation, notes, validation summary), Settings (display style, accent mode/oshi color/custom picker, appearance, language, about + GitHub links), Manual X import (clipboard suggestion, URL field, progress).

Design system: `DesignRadius` tokens 24/18/12; `OshiColor` = 9 seed colors with opacity ramps (bg 0.12 light / 0.18 dark; border 0.42 / 0.60; `.white` special-cased per scheme); 3 accent modes; semantic `locationColor = green`; `StatusBadge` (capsule glass, per-status icon/tint), `VenueTag`, `CoverImageView` (gradient + `music.note.list` placeholder). iOS 26 **Liquid Glass** used in ~9 places plus `.regularMaterial` cards. Dead code to skip: `LiveCardView.swift`, `ThemePalette.background/.border`, `ThemeSystem.warning/success/errorColor`, 6 orphaned l10n keys.

### 1.4 Import system and X integration

Pipeline (all in `Shared/`, fully unit-tested — the parity anchor):

1. **`XURLValidator`**: accepts hosts `x.com`, `www.x.com`, `twitter.com`, `www.twitter.com`, `mobile.twitter.com`; https only; path `/{user}/status/{ascii-digits}`; normalizes to `https://x.com/{user}/status/{id}` stripping query/fragment/extra segments. `firstPostURL(in:)` extracts from free text (regex + trailing-punctuation trim).
2. **`XOEmbedClient`**: GET `https://publish.x.com/oembed?url=…`, ephemeral session, timeouts 12 s request / 15 s resource, **512 KiB cap**. Parses `url`, `author_name`, `html`. Post text = first `<p>…</p>` → HTML-to-plain-text (entities decoded, `<br>` → `\n`, anchor text kept). `linkedURLs` = hrefs, `&amp;` decoded, http(s) only, ordered dedup.
3. **`FXTwitterClient`** (media only): GET `https://api.fxtwitter.com/status/<id>`, **1 MiB cap**; `tweet.media.all[]` filtered to `type == "photo"`, ordered dedup.
4. **`RemoteImageDataClient`**: plain GET, **25 MiB cap**.
5. **`XImportDraftBuilder`** ordering: validate URL (throws before network) → oEmbed (failure → localized `warning` on the draft, still usable) → harvest links from oEmbed HTML + post text → `EventLinkImporter` → FxTwitter images, first downloadable wins; media failures are silent (no warning). `CancellationError` always rethrown.
6. **`EventLinkImporter`**: `NSDataDetector` link extraction; excludes X hosts; supported-parser link preferred, else `t.co` resolve-and-retry, else bare `linkedURL` details. Fetch: `Accept: text/html,application/xhtml+xml`, 2 MiB cap, UTF-8 → **EUC-JP fallback**.
7. **`HeroinesEventPageParser`** (`heroines.jp`): HTML→text normalization, `【公演概要】` section isolation, JP date regexes (`2026年5月20日` / `2026.5.20`), OPEN/START time regexes, `@` venue lines, `出演：` performer split, ticket block parsing (name must match `チケット|券|TICKET`, `¥`/`￥` prices, description capture). **All date/time construction is hardcoded `Asia/Tokyo`.** Returns nil unless a date plus at least one other field parsed (never guesses).
8. **`TicketPlatform`**: dot-anchored host suffix matching for eplus / Ticket Pia / Lawson Ticket / LivePocket / tiget / ZAIKO, each with a fixed "my tickets" URL.

Manual import: paste/clipboard-suggest → same builder → same editor. Retry in editor re-runs the builder and fills **only empty fields**.

### 1.5 Share Extension (iOS-only mechanism)

`OshiLifeShare.appex`: activation rule = ≤1 web URL + text + ≤1 image (25 MiB cap on image). The extension itself runs the entire network import, stages `Incoming/<UUID>/payload.json` (ISO-8601 dates, sorted keys) + optional `shared-image` file in the App Group, then requests `oshilife://import/<UUID>`; if iOS refuses to open the app the payload stays queued and the app drains the oldest on launch/foreground. Save and discard both delete the staged directory. Duplicate detection by exact `sourceURLString` match — advisory banner, duplicates still saveable.

**None of this App Group / appex machinery is needed on Android** — a share intent launches the app process itself (§7.2).

### 1.6 Image storage

`ImageStore.saveJPEG`: decode (any format) → EXIF-orientation-corrected thumbnail, **max 2400 px longest edge** → JPEG **quality 0.85** → `<AppGroup>/Images/<fresh-UUID>.jpg` (uppercase UUID) → returns the **relative** path `Images/<UUID>.jpg`. Reads are nil-tolerant. Orphan cleanup is manual: replace-after-save, rollback-on-failure, delete-with-event.

### 1.7 Localization

String Catalog `Shared/Resources/Localizable.xcstrings`: source language **ja**, full **ja + zh-Hans** coverage, 160 keys, no English, no plurals. Key style `area.thing`; 5 printf-style format keys (`%@`, `%lld`, positional `%1$@`). Referenced via bare `LocalizedStringKey` literals, `String(localized:)`, and `LocalizedStringResource`. Known quirks: countdown suffixes `d/h/m` hardcoded ASCII; `¥` glyph hardcoded (product is JPY-only); `OPEN <time>` note prefix hardcoded; the language picker is a no-op on iOS.

### 1.8 CI/CD

- `.github/workflows/ios.yml` — simulator build + tests on `macos-26`, Xcode path pinned, `pull_request` **unfiltered** (currently would run for Flutter PRs too).
- `.github/workflows/build-ipa.yml` — unsigned Release archive hand-zipped into an IPA artifact on `macos-latest`, PRs to `main` only.
- No signing anywhere by design (placeholder `com.example.*` IDs; real IDs live in gitignored `Config/Local.xcconfig`). Artifacts retained 7 days.

---

## 2. Flutter app — architecture proposal

### 2.1 Repository layout (monorepo)

```
OshiLife/                  # iOS app — untouched
Shared/                    # iOS shared code — untouched
ShareExtension/            # iOS appex — untouched
OshiLifeAndroid/           # NEW: Flutter project root (Android-only)
  pubspec.yaml             #   package name: oshilife
  l10n.yaml
  lib/
    main.dart              #   composition root (mirrors RootView)
    app/                   #   MaterialApp, router, theme wiring
    core/
      design/              #   tokens, OshiTheme extension, shared widgets
      utils/               #   countdown formatter, etc.
    data/
      models/              #   LiveEvent, LiveStatus, TicketOption, VenueSelection
      db/                  #   Drift database, DAOs (LiveStore port)
      settings/            #   AppSettings (SharedPreferences)
      images/              #   ImageStore port
    import/                #   port of Shared/: validator, clients, parsers, draft builder
    features/
      home/                #   dashboard + list + carousel widgets + view model
      live_detail/
      live_editor/
      manual_import/
      settings/
      share_receive/       #   Android share-intent entry flow
  android/                 #   host project: applicationId, share intent-filter, Kotlin shim
  test/                    #   ported behavioral tests (§9)
```

Rationale: one repo keeps the parity workflow (one PR can note both sides), lets CI path-filter cleanly, and mirrors the existing `PascalCase` top-level naming. `flutter create --platforms android --org com.example --project-name oshilife OshiLifeAndroid`.

### 2.2 Layering

Mirror the iOS layering so the two codebases stay mentally aligned — same names, same responsibilities:

| iOS | Flutter |
|---|---|
| `@Observable` view models | Riverpod `Notifier` classes, one per iOS VM, same names (`LiveEditorViewModel` → `liveEditorViewModelProvider`) |
| `LiveStore` (manual fetch + in-memory sort) | Drift DAO `LiveStore`; expose both one-shot fetch and a `watch()` stream. UI subscribes to the stream, which **removes** the iOS-side manual reload-on-foreground dance while keeping identical sort semantics |
| `ImageStore` | `ImageStore` class over `path_provider` + `flutter_image_compress` |
| `AppSettings` (`UserDefaults` write-through) | `AppSettings` Notifier over `SharedPreferences`, same keys (§6.3) |
| `Shared/` (validator/clients/parsers/DTOs) | `lib/import/` pure-Dart library, no Flutter imports — unit-testable on the Dart VM |
| `PendingImportCoordinator` | `ShareReceiveCoordinator` (much simpler on Android, §7.2) |

State management: **Riverpod** (current stable major). Chosen over plain `ChangeNotifier`/provider for route-scoped VM ownership (the iOS "host owns the VM" sheet pattern maps to auto-disposed providers) and testability; chosen over Bloc because the iOS app is plain mutable-state MVVM and Bloc would force a paradigm shift that hurts parity review.

Navigation: **go_router**. Routes:

```
/                      home (card/list per settings)
/event/:id             detail        (push — matches [UUID] path)
/settings              settings      (push)
modal: editor (fullscreen dialog), manual import (fullscreen dialog),
       import editor (fullscreen dialog, PopScope-guarded),
       venue picker (fullscreen dialog), ticket entry (modal bottom sheet, half height)
```

Android back gesture: `PopScope` on the import editor reproduces `interactiveDismissDisabled` + discard confirmation; predictive back left enabled everywhere else.

### 2.3 Database

**Drift** (SQLite) — chosen over Isar/ObjectBox (maintenance risk / binary blobs) and Hive (no queries). Single table `live_events` mapping the V3 schema 1:1:

- `id TEXT PRIMARY KEY` — **uppercase UUID string**, matching Swift's `uuidString` so a future export/import between platforms round-trips identically.
- Dates as ISO-8601 UTC TEXT (drift's `store_date_time_values_as_text: true`) — absolute instants, same semantics as `Date`; human-readable and aligned with the ISO-8601 already used by `payload.json` on iOS.
- `performers_json TEXT NOT NULL DEFAULT '[]'`, `ticket_options_json TEXT NOT NULL DEFAULT '[]'` — keep the denormalized JSON columns (parity beats normalization here; iOS has no relational queries over them).
- `selected_ticket_id TEXT NULL` with the same code-level integrity rule (clearing when the option vanishes) implemented in the `LiveEvent` Dart model's setter, exactly like iOS.
- Drift `schemaVersion = 1` corresponds to logical V3. Document the correspondence in a comment; future iOS V4 changes must land here as a drift migration in the same parity PR.

The three sort/query behaviors (fetchAll two-block sort, upcoming, historical) are ported as pure Dart functions with the same signatures and unit tests — the `startOfDay` pivot uses the device-local timezone via `DateTime.now()` semantics, same as `Calendar.current`.

---

## 3. Recommended packages

Resolve exact versions at implementation time (`flutter pub add`); majors listed are current as of this plan's writing.

| Purpose | Package | Notes / alternative |
|---|---|---|
| State management | `flutter_riverpod` (3.x) | `provider` if the team prefers minimalism; Riverpod recommended (route-scoped VMs, test overrides) |
| Navigation | `go_router` | maintained by the Flutter team |
| Database | `drift` + `drift_flutter` + `sqlite3_flutter_libs`, dev: `drift_dev`, `build_runner` | |
| Preferences | `shared_preferences` | same keys as iOS (§6.3) |
| HTTP | `http` | tiny surface; response-size caps implemented via streamed reads (§7.1). `dio` unnecessary |
| File paths | `path_provider` | app-internal storage; no App Group concept needed |
| Image pick | `image_picker` | uses the Android Photo Picker → no storage permission |
| Image transcode | `flutter_image_compress` | EXIF auto-rotation + JPEG q85; wrapper computes the ≤2400 px box (its min-dimension semantics differ from "max longest edge"). Pure-Dart `image` package is the fallback if native behavior mismatches fixtures |
| Open URLs / maps | `url_launcher` | ticket links, GitHub links, maps (§7.4) |
| Localization | `flutter_localizations` + `intl` (ARB via `gen-l10n`) | §8 |
| App/version info | `package_info_plus` | Settings "About" |
| UUIDs | `uuid` | generate v4, render **uppercase** for storage parity |
| HTML entities | `html_unescape` | for oEmbed text; the `<br>`/tag handling is our own port (§7.1) |
| EUC-JP decode | `charset_converter` | Android `Charset.forName("EUC-JP")` under the hood; only used by the event-page fetch fallback |
| Color picker | `flex_color_picker` | custom accent color (no-opacity mode) |
| Share receive | **none — hand-rolled Kotlin shim** (§7.2) | alternative: `receive_sharing_intent`; hand-rolled preferred: ~80 lines, exact contract, no plugin-maintenance risk, matches the project's zero-dependency ethos |

Explicitly not needed: maps SDK (URL launching only), camera, notifications, background tasks, any networking beyond `http`.

---

## 4. Data strategy

### 4.1 Schema port (the real "data migration")

There is no user data to migrate on Android (new app). The work is porting the schema faithfully — §2.3 table plus:

- `TicketOption` JSON codec must round-trip iOS-written JSON: keys `id` (uppercase UUID), `name`, `price` (int or absent), `description` (string or absent). Write a codec test against literal JSON captured from the iOS format.
- Unknown `statusRawValue` → `planned`; JSON decode failure → `[]`/`"[]"` — replicate the forgiving getters.
- Settings enum reads degrade to defaults on unknown values; `customAccentColor` validity check (components finite, 0…1) replicated.

### 4.2 Cross-platform data portability (future, not in v1)

Users who use both platforms (or move iOS → Android) will eventually want their diary. Neither app has export today. Proposal (backlog item, needs product decision):

- Define `oshilife-export-v1`: a zip of `events.json` (ISO-8601 dates, uppercase UUIDs, relative image paths — i.e. exactly the storage semantics both schemas already share) plus the `Images/` files.
- Because §2.3 deliberately preserves iOS conventions (uppercase UUIDs, relative paths, same JSON shapes), the Flutter importer becomes trivial, and an iOS exporter can be added later **without any schema change on either side**.
- Until then, document clearly that the Android app starts empty.

### 4.3 Timezone decision (needs explicit choice)

iOS stores absolute instants and renders in device-local time; the heroines.jp parser pins **JST**. A user outside Japan sees imported "18:00 開演" shifted. For v1: **replicate iOS behavior exactly** (absolute instants, JST-anchored parsing, device-local rendering) so the two apps always show the same thing given the same data. Flag the JST rendering question as a shared future fix — it must change on both platforms simultaneously or parity breaks.

The `openTime`/`startTime` "day component may disagree with `eventDate`" quirk is also replicated: store full datetimes, render time-of-day only. Do not normalize — normalizing on one platform only would corrupt a future export/import round-trip.

---

## 5. UI strategy

### 5.1 Design direction

**Do not cosplay iOS.** The Android app keeps OshiLife's design language — warm personal cards, 推し色 accents, restrained hierarchy (per `docs/DESIGN.md`) — expressed through Material 3 idioms:

- Material 3 base (`useMaterial3`), `NavigationBar`-free single-screen root (matching iOS's no-tab design), standard app bars, Material motion.
- **Liquid Glass is not portable and we don't chase it.** Glass surfaces map to Material tonal surfaces (`surfaceContainer*` tones) with the existing hairline-stroke + soft-shadow card treatment. `BackdropFilter` blur is reserved for at most the status badge and warning banner if tonal surfaces feel flat — measured, not default (blur is the main jank risk on low-end Android).
- Typography: system Roboto / Noto Sans JP via the default fallback chain; map SwiftUI text styles to the Material scale (`largeTitle→headlineLarge`, `title3→titleLarge`, `footnote→bodySmall`, etc.) in one tokens file. `monospacedDigit` → `FontFeature.tabularFigures()`.
- Radius tokens 24/18/12 carried over verbatim; spacing kept visually equivalent.

### 5.2 Theme system port

`OshiTheme` as a `ThemeExtension`:

- Port the 9 `OshiColor` seed sRGB triples, the ramps (bg 0.12/0.18, border 0.42/0.60), the `.white` scheme special-cases, and the default accent `#C84EF0` — as data, verbatim.
- Three accent modes drive `ColorScheme.fromSeed(seedColor: palette.primary)` plus explicit `primary` override so the accent stays exact (fromSeed alone would tone-shift the 推し色, which defeats the point).
- `appearance` setting → `themeMode`; `locationColor` stays an independent semantic green.
- Status colors/icons: planned = pink + `auto_awesome`, attended = green + `check_circle`, cancelled = neutral + `cancel` (nearest Material Symbols to the SF Symbols).

### 5.3 Screen-by-screen mapping

| iOS | Flutter | Notes |
|---|---|---|
| `LiveListView` (root) | `HomeScreen` | app bar with filter/settings menu (`PopupMenuButton`) + add menu; startup-warning `MaterialBanner`; `RefreshIndicator` in list mode; card/list switch keyed by settings |
| `HomeDashboardView` | `DashboardView` | `PageView(viewportFraction:)` hero carousel; scale 1→0.85 / fade 1→0.62 via `PageController` listener; auto-hiding dots (scroll-notification driven, 700 ms delay); countdown card 40 sp tabular digits on `primary.withOpacity(.10)`; 60 s `Timer.periodic` provider replaces both `TimelineView`s |
| `HomeEventCarouselCard` / `HistoricalEventCard` | stateless widgets | same content hierarchy, combined `Semantics` |
| `LiveListRowView` | `EventListRow` | relative time via `intl` relative formatting, refreshed by the same ticker |
| `EventLinkButton` context menu | `InkWell` + `onLongPress` → menu with Edit | the app's only long-press affordance |
| `LiveDetailView` | `DetailScreen` | sectioned cards; venue row opens maps sheet (§7.4); ticket section with selected-check + platform-aware action button; `SelectableText` for title/notes |
| `LiveEditorView` + hosts | `EditorScreen` (fullscreen dialog) | Material form sections; optional-date pattern; switch-gated time pickers; ticket list with `Dismissible`; inline URL validation + validation summary; duplicate/import banners; route-scoped provider = host-owns-VM pattern |
| `TicketEntryView` | modal bottom sheet | half-height, 3 fields |
| `VenuePickerView` | `VenueSearchScreen` | `SearchAnchor`/search field; behavior depends on §7.5 decision |
| `SettingsView` | `SettingsScreen` | segmented buttons/radio groups; oshi-color swatch rows; `flex_color_picker` dialog; **language setting actually applied** via `MaterialApp.locale` (fixes the iOS no-op — parity note required) |
| `ManualXImportView` | `ManualImportScreen` | clipboard suggestion card (`Clipboard.getData`, checked once); progress button |
| `ContentUnavailableView` (×4) | shared `EmptyState` widget | icon + title + description + optional action |
| `CoverImageView` | `CoverImage` widget | file image with gradient + music-note placeholder; async load |
| `StatusBadge`, `VenueTag` | widgets | capsule/rounded chip, tinted backgrounds per tokens |

Accessibility parity: combined `Semantics` on cards with the `card.accessibility` label format; the 10 iOS accessibility identifiers become widget `Key`s/`Semantics(identifier:)` for integration tests.

---

## 6. Feature parity details

### 6.1 Behaviors that must match exactly (parity contract)

The ported unit tests (§9) pin these; treat the list as the acceptance checklist:

1. X URL normalization (accept/reject table, `https://x.com/{user}/status/{id}` output).
2. oEmbed text extraction: `推し &amp; ライブ<br>最高！` → `推し & ライブ\n最高！`, anchor text kept, no-`<p>` → null.
3. Draft builder ordering, warning-on-metadata-failure, silence-on-media-failure, first-image-wins.
4. heroines.jp parsing: the five fixture pages (dates incl. `【公演概要】` isolation, titles incl. `「…」` capture, venues, OPEN/START, performers, ticket options with prices/descriptions, `¥`/`￥`), JST anchoring, nil-on-non-event.
5. TicketPlatform host matching (dot-anchored, `eplus.jp.example.com` rejected) and `ticketActionURL` selection logic.
6. Event sort orders (three of them), duplicate lookup by exact `sourceURLString`.
7. Editor validation rules, merge precedence (existing → import → author fallback), retry-fills-only-empty-fields, performers splitting.
8. Image pipeline: ≤2400 px, JPEG q0.85, `Images/<UUID>.jpg` relative path, replace/rollback/delete-orphan rules.
9. Countdown format `"{d}d {h}h" / "{h}h {m}m" / "{m}m"` (keep the ASCII suffixes for now — parity over polish; change both platforms together later if localized).
10. Settings defaults and degradation rules.

### 6.2 Deliberate platform differences (documented, not accidental)

- Share arrives via Android intents — no queue, no deep-link scheme, no staged `Incoming/` files (§7.2). `PendingShareImport.warning` semantics survive; the durable-queue behavior does not (unneeded).
- Reactive DB stream instead of manual `load()` on lifecycle events.
- Language setting is functional on Android.
- Maps: Android offers Google Maps / generic `geo:` chooser instead of Apple/Google dialog (§7.4).
- No iPad-style layouts in v1 (Android tablets get the phone layout, responsive enough via the carousel's width math).

### 6.3 Settings key compatibility

Use the same logical keys (`settings.accentColorMode`, etc.) in `SharedPreferences` with the same string values, and store `customAccentColor` as the same JSON shape (string, not Data). The iOS legacy `eventDisplayMode` fallback is **not** ported (no legacy installs on Android). This keeps a future settings export trivially compatible.

---

## 7. Android implementation strategy

### 7.1 Import pipeline port (pure Dart)

- HTTP: one small `CappedHttpClient` helper — streamed response, abort past the cap (512 KiB / 1 MiB / 2 MiB / 25 MiB constants), 12 s per-request timeout, no custom headers except the event-page `Accept`. Errors mirror the Swift enums (`invalidURL` / `invalidResponse` / `responseTooLarge` / `httpStatus(n)`) with the same localized message keys.
- **Regex port caveat (the main porting trap):** Swift `NSRegularExpression` patterns use inline flags `(?i)` / `(?is)` which Dart `RegExp` (JS semantics) does not support → move to constructor flags (`caseSensitive: false`, `dotAll: true`, `multiLine` where needed) per pattern. Lookbehind `(?<!\d)` and backreference `\1` are supported. Every regex lands with its fixture test; no regex is "obviously equivalent."
- oEmbed post-text conversion: iOS uses `NSAttributedString` HTML rendering; Dart port = explicit `<br>`→`\n`, tag strip, `html_unescape` — validated against the pinned test string.
- Encoding fallback: UTF-8 → EUC-JP via `charset_converter` (Shift_JIS is deliberately not handled, same as iOS).
- JST anchoring: construct heroines.jp dates with an explicit `+09:00` offset (fixed-offset construction — JST has no DST — then store as UTC instant), reproducing `TimeZone("Asia/Tokyo")` semantics without a timezone database dependency.

### 7.2 Share receive (replaces the Share Extension)

Android model: `ACTION_SEND` launches **our own app process** — the entire App Group / staging / URL-scheme handoff collapses into direct in-app flow.

- Manifest: `intent-filter` for `ACTION_SEND` with `text/plain` and `image/*` on an `activity-alias` (`.ShareActivity`, label `share.title`), pointing at the single `MainActivity` (`launchMode="singleTask"`).
- Kotlin shim (~80 lines): `onCreate`/`onNewIntent` extract `EXTRA_TEXT` and stream any `EXTRA_STREAM` image URI (cap 25 MiB) → `MethodChannel("oshilife/share")` → Dart `ShareReceiveCoordinator`.
- Dart side reuses the exact iOS resolution order: URL item first (here: first URL found in `EXTRA_TEXT` via `firstPostURL`), image bytes optional, then `XImportDraftBuilder.makeDraft` → import editor route (PopScope-guarded, discard confirmation), duplicate banner from the same store lookup.
- Cold start: the shim buffers the intent until the Dart side signals ready (standard initial-intent pattern), covering the "app not running" case that required the iOS queue.
- Network-in-extension limits don't exist here; the import runs with a progress screen inside the app. `share.processing` / `share.invalid_url` strings reused.

### 7.3 Host project configuration

- `applicationId`: placeholder `com.example.oshilife`, overridable via gradle property (`-PoshilifeAppId=…`) mirroring the `Config/Local.xcconfig` contract; signing config read from a gitignored `android/keystore.properties`.
- `minSdk 24`, `targetSdk` = current (35+); edge-to-edge handled (Android 15 enforcement); adaptive + monochrome launcher icon required (iOS has **no icon yet** either — a shared brand task).
- `<queries>` entries for maps/browser intents (package visibility).
- All endpoints are HTTPS — no cleartext config needed.
- Locale: `MaterialApp.locale` driven by the language setting; also declare `android:localeConfig` for Android 13 per-app language settings.

### 7.4 Maps (no MapKit)

Port `MapService` semantics: name-first query, coordinates fallback, error on both-empty.

- Google Maps: `https://www.google.com/maps/search/?api=1&query=…` (identical URL to iOS).
- Generic: `geo:0,0?q=…` (`geo:lat,lng?q=lat,lng(label)` for coordinates) — opens the user's chosen maps app.
- Venue row → bottom sheet with these two options (mirrors the iOS confirmation dialog; Apple Maps omitted).

### 7.5 Venue search — the one true parity gap (decision needed)

iOS uses `MKLocalSearchCompleter`/`MKLocalSearch`: free, no key, no permission. Android has no equivalent free native service.

| Option | Cost | Notes |
|---|---|---|
| **A. v1: manual entry only (recommended)** | none | Venue + address text fields in the editor; map button still works (name query). Honest parity-minus, ships without keys/billing/ToS risk. Editor UI keeps the venue-section abstraction so B/C slot in later. |
| B. Google Places Autocomplete + Details | API key + billing | Closest UX parity; violates the "no keys/no backend" ethos; requires quota care |
| C. OpenStreetMap Nominatim | free, 1 req/s policy, attribution | No API key but requires debounced, policy-compliant usage + attribution UI; quality varies for JP venues |

Recommendation: ship **A**, design the `VenueSearchService` interface now, decide B vs C after real usage. (Note: imported events from heroines.jp carry venue names anyway — search is only for manual entry.)

---

## 8. Localization strategy

- One-time conversion script (Dart, committed under `OshiLifeAndroid/tool/`): `Localizable.xcstrings` (JSON) → `lib/l10n/app_ja.arb` (template) + `app_zh.arb`. Key mapping: `settings.language.simplified_chinese` → `settingsLanguageSimplifiedChinese`; the 5 format keys become placeholders (`%1$@ %2$@` → `{artist} {title}`, `%lld` → `{code}`). The script emits a `l10n_parity.json` manifest (iOS key ↔ ARB id) so future string additions on either side can be diffed mechanically.
- `l10n.yaml`: `template-arb-file: app_ja.arb`; supported locales `ja`, `zh` (script `Hans`); `localeResolutionCallback` defaults to **ja** (not en) for unsupported locales, matching the iOS development region.
- The 6 orphaned iOS keys are skipped; the conversion script logs them.
- Dates/times via `intl` with the active locale (matches SwiftUI `FormatStyle` output closely; exact format strings are not part of the parity contract — locale-appropriate rendering is).
- `¥` stays hardcoded (product decision inherited from iOS).

---

## 9. Testing strategy

- **Port the behavioral test suite** — the ~35 shared-logic tests are the parity contract: `XURLValidatorTests`, `XOEmbedClientTests`, `FXTwitterClientTests`, `XImportDraftBuilderTests`, `EventLinkImporterTests` (all five HTML fixtures verbatim), `TicketPlatformTests`, `PendingImportStore` equivalents where still applicable, `LiveStore` sort tests, `LiveEditorViewModel` merge/validation tests, `EventCountdownFormatterTests`, `AppSettingsTests`. Fixtures are copied as Dart string constants first (identical bytes); extracting a shared fixture corpus for both platforms is a later, iOS-touching change — out of scope for now.
- Clients tested with injected `http.Client` fakes (same stub pattern as the Swift tests) — no network in CI.
- Widget tests: editor validation flow, empty states, status filter, settings persistence.
- Integration test (deferrable): share-intent flow via `adb shell am start -a android.intent.action.SEND` on an emulator job.
- Golden tests: optional later; not part of v1 (design is intentionally not pixel-identical to iOS).

---

## 10. Release workflow (CI/CD)

### 10.1 New workflow: `.github/workflows/flutter-android.yml`

- Triggers: `pull_request` and `push` to `main`, both filtered to `paths: [OshiLifeAndroid/**, .github/workflows/flutter-android.yml]`; plus `workflow_dispatch`.
- Runner: `ubuntu-latest` (fast, cheap — no macOS needed).
- Job `analyze-and-test`: pinned Flutter via `subosito/flutter-action` with `flutter-version-file: OshiLifeAndroid/pubspec.yaml`, pub cache enabled → `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `build_runner` codegen check (`--delete-conflicting-outputs` + git-diff guard), `flutter test`.
- Job `build-apk`: `flutter build apk --release` (debug-signed by default — the sideloadable-artifact analogue of the unsigned IPA), upload artifact `OshiLife-Android-APK`, `retention-days: 7`, concurrency group with `cancel-in-progress` — all mirroring the iOS workflows' conventions.

### 10.2 Release path (staged)

1. **v1 (now):** CI artifact APK, sideload — exact parity with the unsigned-IPA distribution model.
2. **Play internal testing (when identifiers/signing exist):** tag-triggered `release-android.yml` (`android-v*`): decode keystore from secrets (`KEYSTORE_B64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`), `flutter build appbundle --release`, upload to the internal track (fastlane `supply` or `r0adkll/upload-google-play`). Requires: real `applicationId`, Play Console account, privacy policy URL, data-safety form (declares: no data collected/shared — all local), content rating.
3. Versioning: pubspec `version: X.Y.Z+N`; keep `X.Y.Z` aligned with iOS `MARKETING_VERSION` by convention, build number independent.

### 10.3 Protecting the iOS pipeline (needs owner approval — touches shared CI config, not iOS code)

`ios.yml` currently runs on **every** PR (unfiltered) and `build-ipa.yml` on PRs to `main` — Flutter-only PRs would burn macOS minutes and could red-flag iOS CI for unrelated changes. Proposed additive edit: `paths-ignore: [OshiLifeAndroid/**, docs/**]` on both workflows' `pull_request`/`push` triggers. No build logic changes. If declined, Flutter PRs simply also run iOS CI (wasteful but harmless).

---

## 11. Delivery phases

Each phase ends green (analyze + tests) and independently reviewable. Rough sizes assume a single developer.

| Phase | Scope | Done when |
|---|---|---|
| **M0 — Scaffold** | `flutter create` (Android-only), repo layout, theme tokens + `OshiTheme`, l10n conversion script + generated ARBs, CI workflow (§10.1), README section for the Flutter app | CI green on a hello-world screen with ja/zh strings and 推し色 theming |
| **M1 — Domain + data** | Models, Drift schema + `LiveStore` port with sort tests, `AppSettings`, `ImageStore` port, countdown util | ported unit tests for §6.1 items 6, 8, 9, 10 pass |
| **M2 — Import core** | Validator, capped HTTP client, oEmbed/FxTwitter/image clients, draft builder, EventLinkImporter, heroines parser, TicketPlatform | ported unit tests for §6.1 items 1–5 pass (the big one — all regexes) |
| **M3 — Core UI** | Home (list mode first, then dashboard/carousel), detail, editor (incl. tickets, validation, cover picking), settings, empty states | manual add/edit/delete/filter round-trip works; widget tests |
| **M4 — Import UX** | Manual import screen, share-intent shim + coordinator, import editor flow, duplicate banner, retry | share from X app on device → editor prefilled; parity checklist §6.1 item 7 |
| **M5 — Polish + release** | Maps sheet, accessibility pass, app icon (blocked on brand asset), Play prep (§10.2 step 2 if identifiers ready) | parity matrix (below) fully green or explicitly waived |

Parity governance: add `docs/PARITY.md` in M0 — a feature × platform matrix updated in every feature PR on either platform ("changed on iOS → open Android parity issue" and vice versa). This is the mechanism that keeps two separately-maintained codebases honest.

---

## 12. Risks and mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | **Two codebases, one maintainer** — every feature costs 2× forever | schedule / drift | Parity matrix + ported-test contract (§6.1) makes drift visible; keep Android scope = iOS scope, no Android-only features in v1 |
| 2 | Liquid Glass look can't be reproduced; Android app "feels different" | UX expectations | Deliberate Material-first design direction (§5.1) agreed up front; parity = information architecture + theming, not pixels |
| 3 | Regex/text-processing behavior differs subtly between `NSRegularExpression` and Dart `RegExp` (inline flags, Unicode classes) | silent import corruption | Every regex ported with verbatim fixtures (§9); no regex merges without its test |
| 4 | `publish.x.com` oEmbed / `api.fxtwitter.com` are third-party, unversioned, can break or block any time | import feature outage on **both** platforms | Same graceful degradation as iOS (draft with warning, manual completion); caps + timeouts identical; treat as shared upstream risk, not Android-specific |
| 5 | heroines.jp markup changes break the parser | import quality | Parser already returns nil-safely; fixtures document expectations; changes get fixed on both platforms in one parity PR |
| 6 | Venue autocomplete gap (§7.5) | feature gap vs iOS | Ship manual entry (Option A) with the service interface ready; decide Places/Nominatim later with real usage data |
| 7 | `flutter_image_compress` semantics ≠ ImageIO thumbnailing (dimension rules, EXIF edge cases) | visual diff, storage bloat | Wrapper enforces ≤2400 longest edge; unit test with oriented fixtures; pure-Dart `image` fallback |
| 8 | JST-anchored parsing renders shifted outside Japan (existing iOS bug, inherited) | correctness for overseas users | Replicate for parity now; file a cross-platform issue to fix simultaneously (§4.3) |
| 9 | EUC-JP decode via platform channel (`charset_converter`) could behave differently per device | rare import failures | Only a fallback path; unit test with an EUC-JP fixture; failure degrades to bare-link details, same as iOS |
| 10 | Plugin abandonment (the reason we hand-roll share receive) | maintenance | Dependency list kept minimal (§3); each plugin has a named fallback; share receive is our own Kotlin |
| 11 | Play Store review: app displays X post content and links to ticket vendors | listing risk | App only stores user-initiated imports locally, no scraping beyond oEmbed (X's official embed endpoint) + user-shared links; data-safety form: no collection. Document in listing notes |
| 12 | `.gitignore`d `Config/Local.xcconfig` pattern must not leak into Android signing | secret hygiene | `keystore.properties` + keystore files gitignored from day one (M0), CI uses secrets only |

---

## 13. Open decisions (blocking or shaping implementation)

1. **Venue search v1**: confirm Option A (manual entry) — §7.5.
2. **Final `applicationId`** (and whether it should mirror the eventual real iOS bundle ID) — placeholder `com.example.oshilife` until then.
3. **English localization**: iOS ships ja + zh-Hans only. Add `en` on Android (drops out of the parity contract) or stay ja/zh-Hans? Plan assumes **stay ja/zh-Hans**.
4. **Countdown suffixes** (`2d 5h`): keep ASCII for parity (planned) or localize on both platforms together?
5. **iOS CI path filters** (§10.3): approve the additive `paths-ignore` edit, or accept Flutter PRs triggering macOS jobs?
6. **Export/import format** (§4.2): green-light designing `oshilife-export-v1` in the v1 timeframe, or defer entirely?

---

*Prepared on branch `feature/flutter-android` (based on `agent/ios-ci` @ `d068a9b`). Implementation does not start until these decisions are confirmed.*
