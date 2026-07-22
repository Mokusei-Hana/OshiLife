# OshiLife MVP Implementation Plan

## Summary

Build a new iOS 26+ SwiftUI application with SwiftData, simple MVVM, Japanese as the default language, Simplified Chinese localization, and an App Group-backed Share Extension.

Implementation is organized incrementally: establish persistence and shared infrastructure first, then CRUD, card/detail UI, and finally X sharing. Do not add a backend, accounts, cloud sync, AI parsing, OCR, social features, or X page scraping.

## 1. Project and shared infrastructure

- Create app, unit-test, UI-test, and Share Extension targets with iOS 26.0 deployment targets and Swift 6 concurrency checks.
- Keep the app bundle ID, extension bundle ID, App Group, development team, and URL scheme configurable through xcconfig values. Checked-in values remain non-signable placeholders.
- Put all user-facing strings in a String Catalog, with Japanese as the development language and Simplified Chinese as the initial localization.
- Share only constants, oEmbed DTOs, X URL validation, and pending-import file storage between the app and extension. Keep SwiftData and app-only UI out of the extension target.

## 2. SwiftData model and storage

- Define a schema-versioned `LiveEvent` model with a unique UUID, artist/group, title, event date, optional start time, venue, address, relative cover-image path, ticket/source URL strings, notes, status raw value, and creation/update timestamps.
- Define `LiveStatus` as `planned`, `attended`, or `cancelled`, with localized labels and accessible visual treatments.
- Require artist/group, title, and event date before saving a confirmed Live. Keep incomplete editor/import state outside SwiftData.
- Configure the SwiftData store explicitly in the App Group and access it through a small main-actor service. The Share Extension must never open or mutate the SwiftData store.
- Normalize selected covers to orientation-corrected JPEG, maximum 2400-pixel dimension and 0.85 quality. Store files under `Images/` and only relative paths in SwiftData.
- Save replacement files before model changes, remove a newly written file if persistence fails, and delete superseded/deleted cover files only after the database operation succeeds.
- Use an in-memory `ModelContainer` in unit tests and fallback diagnostics; do not ship sample events.

## 3. Main application experience

- Present a vertical Live-card feed instead of a calendar. Sort upcoming events first in ascending order and past events afterward in reverse chronological order. Include status filtering.
- Provide loading, empty, populated, refresh, and recoverable-error states plus native add, edit, and confirmed-delete flows.
- Design cards around cover art, artist, title, date, venue, and status, with rounded depth, careful typography, and a restrained matched navigation transition.
- Let system navigation and toolbars adopt Liquid Glass automatically. Use custom glass for buttons, filters, and status/control overlays; group adjacent effects with `GlassEffectContainer` and avoid glass on every content surface.
- Support Dynamic Type, VoiceOver labels, sufficient contrast, light/dark appearance, Reduce Motion behavior supplied by native transitions, Reduce Transparency material fallback, and a useful missing-cover placeholder.
- Show cover, event information, notes, ticket/source links, status, and edit/delete actions on the detail screen.
- Resolve venue plus address with `MKLocalSearch` when the map action is selected and open the best `MKMapItem`. Show a localized failure without requesting user location permission.
- Accept only HTTP(S) ticket/source links for actions. Preserve invalid editor input and show inline validation.

## 4. X Share Extension and handoff

- Activate for limited URL, text, and optional image attachments; never use an unrestricted activation predicate.
- Inspect all item providers, preferring `UTType.url`, then extract HTTPS links from plain text. Accept normalized `x.com` and legacy `twitter.com` status URLs only.
- Fetch `https://publish.x.com/oembed?url=...` with an ephemeral session, explicit timeouts, cancellation, HTTP validation, and a 512 KiB response limit.
- Decode author and canonical URL. Isolate the first post paragraph from returned HTML and use native HTML conversion to produce editable plain text. Parsing failures are recoverable.
- Prefill artist/group from the author, notes from post text, and source URL from the canonical/shared URL. Never infer the event title or date.
- Use an image attachment supplied by the host when it is no larger than the extension input bound. If absent, continue without a cover. Do not scrape X or treat oEmbed as a media API.
- Atomically stage `PendingShareImport` JSON plus any shared image under `Incoming/<UUID>/` in the App Group.
- Request an `<configured-scheme>://import/<UUID>` handoff via `NSExtensionContext`; never use `UIApplication` in the extension.
- If iOS refuses or delays opening the app, retain the payload and tell the user to open OshiLife. Check the oldest queued payload on app launch and every active-scene transition.
- Open imports in the normal editor. Persist only after validation and explicit save. Confirm discard, then remove the staged directory.
- Detect an existing Live with the same source URL. Offer to open the saved Live (and consume the redundant pending import) or continue editing a duplicate.
- When the extension could stage only a URL, show its warning and provide an in-app oEmbed retry. A failed retry must not block manual completion.
- Consume successful imports and their staged images. Do not automatically expire valid queued imports.

## Issues reviewed before implementation

- X oEmbed does not expose media URLs, so cover import depends entirely on optional image attachments from the host.
- Opening a containing app from a Share Extension is not guaranteed; durable App Group queueing is required.
- App and extension sandboxes are separate. Both signed targets must use the same registered App Group.
- Cross-process SwiftData writes can contend. Only the main app mutates the database.
- Extensions have limited time and memory. Network work is cancellable; oEmbed and shared image sizes are bounded.
- X attachment shapes and oEmbed HTML can change. URL/HTML parsing fails into editable manual input and is fixture-tested.
- Absolute container locations can change. All persisted image locations are relative paths.
- Liquid Glass can harm readability and performance when overused. Prefer native components and limited custom effects.
- SwiftData schema decisions are expensive to retrofit. Start with explicit versioning and a migration-plan type.
- Share behavior must be accepted on a signed physical device using the real X app.

## Incremental delivery

1. Project targets, signing placeholders, localization, schema, storage services, and storage tests.
2. Live CRUD, editor validation, list sorting, and functional navigation.
3. Card/detail polish, image handling, MapKit, Liquid Glass, animation, and accessibility.
4. Pending-import App Group storage and main-app URL/scene routing.
5. Share Extension, oEmbed parser/client, attachment handling, retries, and fallback queueing.
6. Localization, accessibility, persistence, performance, and device integration verification.

## Test plan

- Unit-test status mapping, required-field and URL validation, schema creation, CRUD, duplicate lookup, and upcoming/history sorting.
- Test cover normalization, invalid images, replacement rollback, deletion, missing files, and orphan cleanup behavior.
- Validate Japanese and Simplified Chinese String Catalog coverage and localized date/time/status/error presentation.
- Exercise card/detail/editor layouts with long or missing content, Dynamic Type, VoiceOver, dark mode, Reduce Motion, and Reduce Transparency.
- Exercise MapKit success, empty input, no-result, offline, and malformed-address cases.
- Test oEmbed paragraph parsing plus successful, malformed, oversized, HTTP-error, timeout, and cancellation behavior through recorded/stubbed responses.
- Test X and legacy Twitter URLs, query stripping, plain-text extraction, unsupported hosts, malformed status IDs, optional images, and absent URLs.
- Test FIFO queueing, cold/warm app handoff, scene reactivation, duplicate URLs, retry, cancel/discard, save/consume, and staged-file cleanup.
- UI-test launch and the manual add/editor route.
- On a signed device, share real X posts with and without image attachments and verify both immediate handoff and queued fallback.

## Assumptions

- The repository starts without an existing Xcode project or code requiring migration.
- Native Apple frameworks are sufficient; no third-party package is needed.
- Japanese is the default UI language and Simplified Chinese ships in the MVP.
- The X API, X page scraping, AI parsing, media extraction, OCR, and timetable recognition remain excluded.
- A configurable custom URL scheme is sufficient for MVP handoff; universal links require out-of-scope web infrastructure.
- Final identifiers, App Group registration, development team, app icon, brand assets, privacy metadata, and store metadata are supplied during signing and distribution setup.
