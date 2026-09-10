# OshiLife Codebase Map

## 1. Tech Stack & Architecture

OshiLife is a native **iOS 26+ Swift 6** application, not a Flutter/Dart project. UI is **SwiftUI** (plus UIKit for the Share Extension), state uses Apple's **Observation** framework (`@Observable`, `@State`, `@Bindable`, environment injection), and persistence uses **SwiftData** plus App Group files and `UserDefaults`. There are no third-party package dependencies in the Xcode project.

| Concern | Implementation |
|---|---|
| App/UI | SwiftUI; PhotosUI; MapKit; UIKit bridge/Share Extension |
| State | Observation-based view models/services; `AppSettings` in the SwiftUI environment; `@AppStorage` for display mode |
| Navigation | `NavigationStack`, UUID navigation path/destinations, and sheets; no tabs and no `go_router` |
| Database | SwiftData `ModelContainer`, versioned schemas V1–V3, lightweight migrations; no Drift/DAOs |
| File persistence | App Group `Incoming/` JSON/images for staged imports and `Images/` JPEGs for covers |
| Preferences | `UserDefaults` through `AppSettings`; display mode through `@AppStorage` |
| Localization | String Catalog at `Shared/Localizable.xcstrings`, compiled into app and extension; `String(localized:)`/localized SwiftUI keys |
| Networking | Foundation `URLSession`: X oEmbed, FxTwitter media, linked event pages |
| Architecture | Small MVVM/service design: SwiftUI views → observable view models/coordinator → stores/services → SwiftData/files/network. `Shared/` is compiled into both app and Share Extension. No repository layer. |

`AppSettings.language` and accent-color mode are persisted and exposed in Settings, but current app composition only applies `appearance.colorScheme`; it does not inject a locale or dynamically apply the selected accent mode.

## 2. Project Structure

```text
.
├── OshiLife.xcodeproj/                 # Targets, build phases, shared OshiLife scheme
├── Config/
│   ├── Base.xcconfig                   # Swift/iOS versions, IDs, App Group, URL scheme
│   ├── Debug.xcconfig
│   └── Release.xcconfig
├── OshiLife/
│   ├── App/                            # App entry and dependency composition
│   ├── Models/                         # SwiftData schema/model and settings/value types
│   ├── Services/                       # Persistence, images, maps, venue lookup
│   ├── ViewModels/                     # List/editor/import state and orchestration
│   ├── Views/
│   │   └── Components/                 # Reusable image, badge, and venue picker UI
│   ├── Resources/Assets.xcassets/      # Accent/asset catalog
│   ├── Info.plist
│   └── OshiLife.entitlements
├── Shared/                             # Import models, clients, parsers, App Group utilities, strings
│   └── Localizable.xcstrings
├── ShareExtension/                     # UIKit X share intake and app handoff
├── OshiLifeTests/                      # Unit tests for models, stores, importers, clients, view models
├── OshiLifeUITests/                    # End-to-end app UI tests
└── .github/workflows/                  # CI build/test and unsigned IPA packaging
```

## 3. App Entry & Navigation

- Entry: `OshiLife/App/OshiLifeApp.swift` — `OshiLifeApp` creates the persistent SwiftData container, falls back to an in-memory container with a warning, and installs it with `.modelContainer`.
- Shell/composition root: `OshiLife/App/RootView.swift` — constructs `LiveStore`, `ImageStore`, optional `PendingImportStore`, and `AppSettings`, then presents `LiveListView`.
- Main shell: `OshiLife/Views/LiveListView.swift` — one `NavigationStack`; there is no `TabView`. It owns list/home display switching, filtering, UUID detail navigation, add/edit/import sheets, lifecycle refresh, and custom URL intake.
- Routes: UUID path → `LiveDetailView`; toolbar link → `SettingsView`; sheets → `LiveEditorHost`, `ManualXImportView`, and `ImportEditorHost`. `oshilife://import/<UUID>` is handled by `PendingImportCoordinator` via `.onOpenURL`.
- There is no `go_router` configuration; this is not a Flutter project.

| Screen | Path |
|---|---|
| Concert journal/card collection and monthly agenda | `OshiLife/Views/LiveListView.swift` |
| Live detail | `OshiLife/Views/LiveDetailView.swift` |
| Create/edit/import editor | `OshiLife/Views/LiveEditorView.swift` |
| Manual X URL import | `OshiLife/Views/ManualXImportView.swift` |
| Settings/about | `OshiLife/Views/SettingsView.swift` |
| Venue search picker | `OshiLife/Views/Components/VenuePickerView.swift` |
| X Share Extension UI | `ShareExtension/ShareViewController.swift` |

## 4. Presentation Layer

- `LiveListView` composes concert-pass cards and archive rows in collection mode, and date-stamped rows grouped by month in agenda mode. Collection mode includes upcoming, attended, and all remaining events (including cancelled and past planned events). It retains the countdown, carousel focus, display preference, filter menus, and presentation routing; its page indicator is native SwiftUI.
- `LiveDetailView` renders the cover, schedule, venue/map actions, performers, ticket options, notes, external links, and delete confirmation.
- `LiveEditorView` is a scrollable concert workspace used by `LiveEditorHost` and `ImportEditorHost`; paper panels contain identity, status, schedule, and location. Adaptive destination tiles open performers, ticket selection, links, and notes pages. It retains direct `LiveEditorViewModel` bindings, PhotosUI, and the `VenuePickerView` sheet.
- Shared UI: `CoverImageView` loads stored cover images/fallback artwork; `StatusBadge` visualizes `LiveStatus`; `LiveCardView` is an alternate card component but is not currently referenced by the main list.
- Design tokens and reusable journal surfaces, buttons, headings, date stamps, dashed dividers, and notices live in `Views/Components/EventPresentation.swift`. The concert journal uses dynamic warm paper/ink surfaces, vermilion accents, serif display type, and monospaced schedule details. `RootView` installs its tint. The Share Extension mirrors the palette locally because it is a separate target. See `UI_REDESIGN.md` for design and validation details.
- Dialogs/sheets are declared inline in `LiveListView`, `LiveDetailView`, `LiveEditorView`/hosts, and `VenuePickerView`; there is no separate dialog layer.

## 5. State & Business Logic

| Type | Path | Responsibility / consumers |
|---|---|---|
| `LiveListViewModel` | `OshiLife/ViewModels/LiveListViewModel.swift` | Loads, status-filters, and deletes events; used by `LiveListView`. |
| `LiveEditorViewModel` | `OshiLife/ViewModels/LiveEditorViewModel.swift` | Editor fields, validation, imported-data merge/retry, image/store transaction; used by editor hosts/view. |
| `ManualXImportViewModel` | `OshiLife/ViewModels/ManualXImportViewModel.swift` | Clipboard suggestion, X URL validation, async draft creation; used by `ManualXImportView`. |
| `PendingImportCoordinator` | `OshiLife/ViewModels/PendingImportCoordinator.swift` | Reads staged queue/custom URLs, loads images, detects source-URL duplicates, consumes/discards imports; owned by `LiveListView`. |
| `AppSettings` | `OshiLife/Models/AppSettings.swift` | Observable `UserDefaults` preferences; created by `RootView`, edited by `SettingsView`. |
| `LiveStore` | `OshiLife/Services/LiveStore.swift` | Main-actor SwiftData fetch/lookup/insert/save/delete/rollback; used by list/editor/import state. |
| `ImageStore` | `OshiLife/Services/ImageStore.swift` | Normalizes cover images to JPEG and reads/removes App Group files; used throughout event UI/editor. |
| `ModelContainerFactory` | `OshiLife/Services/ModelContainerFactory.swift` | Builds persistent App Group or in-memory SwiftData containers with migration plan. |
| `VenueSearchService` | `OshiLife/Services/VenueSearchService.swift` | Observable MapKit autocomplete and result resolution; owned by `VenuePickerView`. |
| `MapService` | `OshiLife/Services/MapService.swift` | Builds/opens Apple or Google Maps URLs; called directly by `LiveDetailView`. |
| Import services | `Shared/XImportDraftBuilder.swift`, `Shared/XOEmbedClient.swift`, `Shared/FXTwitterClient.swift`, `Shared/EventLinkImporter.swift` | Build an editable draft from X metadata, optional media, and supported linked event pages; used by manual import, retry, and Share Extension. |

There are no provider packages, controller/notifier framework classes, or repository abstractions.

## 6. Data Layer

- `LiveEvent` is a typealias to `OshiLifeSchemaV3.LiveEvent` (`OshiLife/Models/LiveEvent.swift`). It stores identity, artist/title, date/open/start times, venue/address/coordinates, relative cover path, ticket/source URLs, notes/status, timestamps, performers JSON, ticket-options JSON, and selected ticket ID.
- `OshiLife/Models/OshiLifeSchema.swift` defines schemas V1–V3 and `OshiLifeMigrationPlan` with lightweight V1→V2→V3 migrations. The sole SwiftData entity is `LiveEvent`; there are no table relationships or DAOs.
- `TicketOption`, `EventImportDetails`, and `PendingShareImport` live in `Shared/PendingShareImport.swift`. Performer and ticket arrays are encoded into `LiveEvent` string fields rather than related entities.
- `PendingImportStore` stages one `payload.json` and optional image per import under App Group `Incoming/<UUID>/`; `ImageStore` stores normalized covers under `Images/`. SwiftData stores only relative image paths.
- `ModelContainerFactory` puts the SwiftData store in the same configured App Group. Only the main app writes SwiftData; the extension writes staged files.

## 7. Feature-to-Code Map

| Feature → UI → State/Logic → Data |
|---|
| Home / next live → `LiveListView`, `HomeEventCarouselCard`, `HistoricalEventCard` → `LiveListViewModel`; countdown/upcoming/history selection currently lives in `LiveListView` → `LiveStore` → `LiveEvent` |
| Live/event management → `LiveListView`, `LiveDetailView`, `LiveEditorView` → `LiveListViewModel`, `LiveEditorViewModel`, `MapService` → `LiveStore`, `ImageStore` → `LiveEvent` |
| Schedule (event date/open/start time; no separate calendar screen) → `LiveEditorView`, `LiveDetailView`, home/list cards → `LiveEditorViewModel` → `LiveEvent` |
| Tickets → ticket sections in `LiveEditorView`/`LiveDetailView` → imported/editor ticket selection in `LiveEditorViewModel` → `TicketOption` encoded in `LiveEvent.ticketOptionsJSON` |
| X import (share) → `ShareViewController` → `XURLValidator`, `XImportDraftBuilder`, `PendingImportCoordinator`, `ImportEditorHost` → `PendingImportStore` → finalized `LiveEvent`/cover |
| X import (manual URL) → `ManualXImportView` → `ManualXImportViewModel`, `XImportDraftBuilder`, then `PendingImportCoordinator`/editor → in-memory `PendingShareImport` → finalized `LiveEvent`/cover |
| Linked event URL metadata import → import editor fields (no standalone URL-import screen) → `EventLinkImporter` + `HeroinesEventPageParser` (currently supports `heroines.jp`) → `EventImportDetails` inside draft |
| Venue search/maps → `VenuePickerView`, venue action in `LiveDetailView` → `VenueSearchService`, `MapService` → coordinates/address on `LiveEvent` |
| Settings → `SettingsView` → `AppSettings`, `AppVersionInfo` → `UserDefaults`/bundle metadata |
| Localization → all views/services and Share Extension → localized keys/resources → `Shared/Localizable.xcstrings` |

There is no oshi-profile/settings feature, global event text search, tabbed schedule, or separate ticket inventory feature in the current implementation.

## 8. UI Refactor Boundaries

Generally safe to redesign without changing behavior: view layout/styling in `OshiLife/Views/`, card/row composition, inline section visuals, and reusable components under `OshiLife/Views/Components/`. Preserve bindings, callbacks, accessibility identifiers, sheet/navigation wiring, and localization keys.

Tightly coupled areas requiring care:

- `LiveListView.swift` combines presentation with filtering-derived home sections, countdown calculation, carousel behavior, lifecycle loading, navigation state, import queue handling, and all top-level sheets.
- `LiveEditorView.swift` directly binds the complete editable model, loads PhotosPicker data, invokes save, and controls import/duplicate/discard flows.
- `LiveDetailView.swift` directly invokes `MapService` and owns delete/map dialogs.
- `VenuePickerView.swift` owns and drives `VenueSearchService`; `ShareViewController.swift` combines UIKit UI with extension ingestion/handoff.

Do not casually modify during a UI-only refactor: `OshiLife/Models/OshiLifeSchema.swift`, `OshiLife/Models/LiveEvent.swift`, `ModelContainerFactory`, `LiveStore`, `ImageStore`, `PendingImportStore`/shared import Codable types, `SharedConstants`, import clients/parsers, entitlements/Info plists, or Xcode target/build configuration. These define migrations, persistence formats, App Group interoperability, URL handoff, and network import behavior.

## 9. GitHub Actions

| Workflow | Triggers | Purpose |
|---|---|---|
| `.github/workflows/ios.yml` | Push to `main`, all pull requests, manual dispatch | On `macos-26`/Xcode 26.6, builds for testing and runs simulator tests on iPhone 17; uploads build/test `.xcresult` bundles for 7 days. Concurrent runs for the same workflow/ref cancel older runs. |
| `.github/workflows/build-ipa.yml` | Push to `main`, pull requests targeting `main`, manual dispatch | Archives an unsigned Release app, packages `OshiLife.ipa`, and uploads it for 7 days. |
