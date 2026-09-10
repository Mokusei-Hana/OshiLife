Redesign and rebuild the entire existing OshiLife UI from scratch.

The current UI design must NOT be preserved.

Treat the existing UI only as a reference for:

- existing features
- available actions
- required fields
- navigation behavior
- bindings
- data flow
- business logic

Do NOT use the existing visual design, layout structure, card composition, spacing, hierarchy, styling, or page composition as a baseline.

## Core Requirement

Preserve all existing functionality.

Do not remove, simplify, or omit existing features just because they are difficult to fit into the new design.

The goal is:

**Completely new UI, same product functionality.**

You may substantially rewrite, restructure, split, merge, or replace existing SwiftUI view code as needed.

Reuse the existing business logic and data layer.

Do not reuse the old UI structure unless a specific interaction is already optimal and genuinely fits the new design.

## Preserve

All existing behavior and capabilities must continue to work, including:

- live/event creation
- editing
- deletion
- home/card mode
- list mode
- filtering
- countdown behavior
- event navigation
- live detail information
- venue/map actions
- performers
- ticket options
- notes
- external links
- PhotosPicker
- venue picker
- X URL import
- Share Extension import
- imported-data editing
- duplicate handling
- retry behavior
- pending imports
- custom URL intake
- settings
- localization
- Light/Dark Mode
- persistence
- SwiftData compatibility

Do not delete existing fields, controls, flows, or actions.

## Do Not Modify Core Logic

Avoid unnecessary changes to:

- SwiftData models and migrations
- `LiveStore`
- `ImageStore`
- persistence formats
- X import clients/parsers
- App Group storage
- Share Extension ingestion
- URL handoff
- existing business logic
- existing localization keys

Minimal non-UI changes are allowed only when strictly required to support the redesigned interface.

## Design Goal

The result should feel like a newly designed Apple first-party application for 推し活.

Target visual language:

- iOS 27
- modern SwiftUI
- Liquid Glass
- Apple Calendar
- Apple Wallet
- Apple Maps
- Apple Settings

Do not merely modernize the old UI.

Do not simply:

- adjust padding
- change corner radii
- change fonts
- change colors
- restyle old cards
- add blur
- remove blur
- add glass effects
- tweak existing layouts

Those changes alone are insufficient.

Reconsider each screen from first principles.

## Design Principles

Use:

- strong visual hierarchy
- generous whitespace
- native typography
- semantic system colors
- SF Symbols
- native SwiftUI controls
- restrained accent color
- clean information grouping
- native navigation and sheet behavior
- subtle depth and motion
- content-first layouts

Avoid:

- repeated card stacks
- dashboard-like layouts
- Material Design patterns
- excessive glass
- excessive gradients
- excessive borders
- excessive shadows
- decorative UI without functional purpose

Liquid Glass should primarily belong to interface chrome such as:

- navigation controls
- toolbars
- sheets
- floating controls
- overlays
- menus

Do not turn every content container into glass.

## Major Screens

Fully redesign all existing major UI areas:

- `LiveListView`
- Home/carousel presentation
- `LiveListRowView`
- `LiveDetailView`
- `LiveEditorView`
- `ManualXImportView`
- `SettingsView`
- `VenuePickerView`
- existing shared components
- loading states
- empty states
- error states
- dialogs
- sheets
- menus
- status presentation

Do not preserve their current visual composition by default.

## Home

Design the home experience from scratch.

The next live should be the strongest visual focus.

Clearly communicate:

- artist
- event title
- date
- countdown
- venue
- OPEN
- START
- event status

Upcoming and historical events should use clearly different levels of emphasis.

Preserve the existing home/card and list-mode functionality, but the visual implementation may be completely replaced.

## Live Detail

Rebuild the detail page composition from scratch.

Create a clear, premium hierarchy for:

- cover
- artist
- event title
- schedule
- venue
- map actions
- performers
- ticket information
- notes
- external links
- status
- edit/delete actions

All existing functionality must remain available.

## Editor

Completely redesign the editor UI while preserving every field and workflow.

You may reorganize the editor into better native sections, sheets, menus, pickers, or progressive groups.

Preserve:

- all editable fields
- validation
- save behavior
- import editing
- PhotosPicker
- venue selection
- duplicate flows
- retry flows
- discard behavior

Do not remove fields to make the layout cleaner.

## X Import

Redesign the X import presentation from scratch.

Keep the existing import implementation unchanged.

The new UI should clearly present:

- URL input
- clipboard suggestion
- validation
- loading
- errors
- import progress/state
- transition into editable imported data

## Settings

Completely redesign Settings using Apple-native patterns.

Preserve all existing settings and About content.

Do not invent new settings.

## Venue Picker

Completely redesign the venue search presentation while preserving the existing MapKit search logic and behavior.

Use Apple Maps/Search interaction patterns as inspiration.

## Shared Design System

Create or replace shared UI components as needed.

A small centralized design system is encouraged for:

- spacing
- typography
- radii
- materials
- accent handling
- event presentation
- status presentation
- section presentation

Do not over-engineer abstractions.

## Implementation

Read `PROJECT_STRUCTURE.md` first for the current codebase structure and refactor boundaries.

Then implement the redesign directly.

Do not preserve old UI code merely to minimize diff size.

A large view-layer diff is acceptable and expected.

Do not stop for confirmation.

Do not output a design proposal instead of implementing the code.

Do not perform unrelated refactors.

Perform only the minimum local checks required to catch obvious syntax/code errors.

## Git

Work only on the existing local branch:

`refactor/ios27-ui`

Do not commit.

Do not push.

Do not modify GitHub Actions.

Leave all completed changes uncommitted for manual review.

## Final Requirement

When finished, the application should visually feel like a different, newly designed product while retaining the full functionality of the current OshiLife implementation.

If an old UI structure conflicts with the new design, replace the UI structure.

If an existing feature conflicts with the new design, redesign how the feature is presented — do not remove the feature.
