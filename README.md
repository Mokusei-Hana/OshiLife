# OshiLife

OshiLife is an iOS 26+ SwiftUI and SwiftData app for keeping a personal diary of idol live events. It includes an X Share Extension that stages editable imports through an App Group without using the X API or page scraping.

## Before building

1. Open `OshiLife.xcodeproj` in Xcode 26 or later.
2. Copy the relevant placeholder values from `Config/Base.xcconfig` into an untracked `Config/Local.xcconfig` and change:
   - `APP_BUNDLE_IDENTIFIER`
   - `APP_GROUP_IDENTIFIER`
   - `DEVELOPMENT_TEAM`
3. Register that App Group in the Apple Developer portal and enable it for both `OshiLife` and `OshiLifeShare`.
4. Keep the app and extension signing teams aligned.
5. Add final app-icon and brand assets before distribution.

The default URL scheme is `oshilife`; both targets read the configured value at runtime.

## Verification

Run the `OshiLifeTests` and `OshiLifeUITests` schemes in Xcode. Share Extension handoff must also be verified on a signed physical device from the X app, because the host payload and app-opening decision cannot be fully reproduced by unit tests.

## Storage boundaries

- The main app is the only process that writes SwiftData.
- Pending share JSON and image attachments are stored under the App Group's `Incoming/` directory.
- Normalized cover images are stored under `Images/`, while SwiftData stores relative paths only.
