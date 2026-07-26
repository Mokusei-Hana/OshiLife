# OshiLife Android (Flutter)

The Android companion app for OshiLife. The SwiftUI iOS app at the
repository root is the **reference implementation**; this app mirrors its
features and design language with Material 3 idioms. Scope, architecture,
and parity rules live in [`docs/FLUTTER_MIGRATION_PLAN.md`](../docs/FLUTTER_MIGRATION_PLAN.md).

## Setup

1. Install Flutter (stable, 3.44+) with the Android toolchain.
2. `flutter pub get` — also generates the localizations
   (`lib/l10n/app_localizations*.dart`).
3. `dart run build_runner build --delete-conflicting-outputs` — regenerates
   the drift database code (`lib/data/db/database.g.dart`).

## Checks

```sh
dart format .
flutter analyze
flutter test
```

CI (`.github/workflows/flutter-android.yml`) runs the same steps plus a
staleness guard for generated files, and builds a debug-signed release APK
artifact — the Android analogue of the iOS unsigned-IPA workflow.

## Localization

Japanese (source) and Simplified Chinese, converted from the iOS String
Catalog — the single source of truth:

```sh
dart run tool/convert_xcstrings.dart   # reads ../Shared/Resources/Localizable.xcstrings
```

Regenerate and commit the ARB output in the same PR as any catalog change.
`lib/l10n/l10n_parity.json` maps iOS keys to ARB ids for parity audits.

## Conventions shared with iOS (do not break)

- UUIDs are stored as **uppercase** strings; dates as ISO-8601 UTC text.
- `performersJson` / `ticketOptionsJson` are denormalized JSON columns with
  `'[]'` defaults; `TicketOption` JSON omits null fields.
- Cover images: longest edge ≤ 2400 px, JPEG quality 0.85, stored under
  `Images/<UUID>.jpg` with **relative** paths in the database.
- Preference keys (`settings.*`) and raw values are identical to iOS.
- Drift `schemaVersion 1` == iOS schema V3; iOS schema changes land here as
  drift migrations in the same parity PR.

## Application id

The tracked id is the `com.example.oshilife` placeholder. Override it
without touching tracked files (mirrors the iOS `Config/Local.xcconfig`
contract):

```sh
flutter build apk --release -P oshilifeApplicationId=your.real.id
```
