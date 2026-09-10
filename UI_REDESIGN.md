# OshiLife concert journal

The presentation layer is rebuilt around a concert journal: warm paper, deep ink,
vermilion highlights, serif event titles, large calendar stamps, and perforated
concert passes. The design uses native SwiftUI layouts, controls, navigation,
PhotosUI, and MapKit search. No image assets or third-party dependencies are needed.

## Screen design

| Surface | New presentation | Retained interactions |
| --- | --- | --- |
| Collection | Artwork-first concert passes; focused countdown; upcoming, archive, and remaining-event panels | Swipe and focus tracking, all status filters, context-menu edit, detail navigation, refresh |
| Agenda | Month headings with date-stamped event rows on paper panels | All events, status filtering, detail navigation, context-menu edit, refresh |
| Main shell | Compact app masthead, filter/display strip, persistent import/add action dock | Persisted card/list mode, settings navigation, manual creation/import, custom URL intake, foreground queue refresh |
| Detail | Large concert pass, ticket action, itinerary and venue panel, performers, ticket inventory, notes, links | Edit, confirmed delete, both map providers and errors, selected ticket and every available option, external links, selectable text |
| Create/edit/import | Cover workspace and labeled fields, schedule/location panels, adaptive destination tiles | Title, artist, cover pick/remove, status, optional date/open/start times, date clearing, venue select/clear, validation, save/cancel |
| Editor destinations | Dedicated paper workspaces for performers, tickets, links, and notes | All existing subpage routes, performer text, optional selected ticket, prices/descriptions, both URL fields and validation, multiline notes |
| Import editor | Notices above the shared editor | Duplicate opening, metadata retry/loading, save/consume, discard confirmation, interactive dismissal protection |
| Manual import | Ink-colored introduction and a paper URL workspace | Clipboard suggestion, editable URL, inline errors, disabled/loading state, cancel and draft handoff |
| Venue picker | Searchable location notebook with result panels | Autocomplete, result resolution/loading, error dismissal, selection and cancel |
| Settings | App identity panel, preference groups, full-width selection cards | Appearance/accent/language values and persistence, all subpages, about metadata, GitHub/feedback links |
| Share Extension | Scrollable journal masthead and status panel | Existing processing, staged data, handoff, queued/error/result messages, completion button |

Empty/loading states, status badges, cover fallback artwork, countdowns, and notices
use the same visual system. System confirmation dialogs, photo pickers, and date
popovers retain their native presentation.

## Accessibility and compatibility

- Dynamic light/dark colors, scalable text styles, wrapping labels, bounded reading
  widths, adaptive editor tiles, and vertical alternatives for time/action layouts.
- Text and SF Symbols accompany status colors; selected settings/tickets expose
  selected accessibility traits. Decorative artwork and pagination are hidden.
- Existing accessibility identifiers remain; editor and import controls add stable
  identifiers for regression coverage.
- Existing reduced-motion behavior is retained for carousel indicator transitions.
- Japanese and Simplified Chinese remain supported. New collection/action labels
  and countdown units are translated in the existing string catalog.
- Models, schemas, stores, services, view models, import parsing, App Group formats,
  URL schemes, entitlements, and project build settings are unchanged. Only the
  Share Extension's `configureUI()` method changes.
- Language and accent-mode settings retain their pre-existing persisted semantics.
  As before, they do not dynamically override locale or extract an artwork color;
  appearance continues to apply through `RootView`.

## Validation

Completed in the Linux workspace:

- Swift 6 frontend syntax parsing of all application, extension, shared, and test
  Swift sources.
- String-catalog JSON parsing, preservation of every existing translation, and
  coverage checks for new labels and both supported languages.
- Source audit of editor bindings, accessibility identifiers, unchanged import
  hosts/coordinator wiring, and unchanged non-UI files.
- `git diff --check`.

Added UI regression coverage for creation/relaunch/reopening persisted fields and
confirmed deletion, manual import URL rejection without networking, and access to
all settings destinations. The existing launch/editor/settings tests remain.

Xcode and the iOS SDK/simulator are not installed here. Syntax parsing does not
replace SwiftUI type checking or execution. Build and run the OshiLife scheme on
macOS before release, then verify:

1. Both display modes and all statuses with zero, one, and many events; focused
   countdown after paging and filtering; persistence after relaunch.
2. Create/edit with every optional field, photo replacement/removal, date clearing,
   both time toggles, performers, ticket selection/none, URLs, and long notes.
3. Manual and shared import success, missing metadata/retry, duplicates, discard,
   queued imports, and cold/warm custom-URL handoff.
4. Venue results, no results, resolution errors, and Apple/Google Maps opening.
5. Japanese/Chinese, light/dark/system appearance, VoiceOver, Reduce Motion,
   accessibility text sizes, narrow iPhones, landscape, and iPad split view.
