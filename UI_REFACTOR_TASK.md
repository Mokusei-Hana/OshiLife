Refactor the entire existing OshiLife UI in the current repository.

Do not output a plan or analysis first.

Read `PROJECT_STRUCTURE.md` first, inspect only the implementation files necessary for the task, then immediately begin modifying the code. Do not re-analyze the entire repository unless required by an implementation issue.

## Goal

Fully redesign the existing Presentation Layer into a polished, highly native Apple-style interface using modern SwiftUI and an **iOS 27 / Liquid Glass** visual language.

Preserve all existing functionality, navigation behavior, bindings, persistence, import flows, localization, and data compatibility.

This is a native SwiftUI project.

Do not introduce Flutter, Material Design, third-party UI frameworks, or a new application architecture.

## Scope

Refactor the existing UI only.

Primary UI areas include:

- `OshiLife/Views/LiveListView.swift`
- `OshiLife/Views/LiveDetailView.swift`
- `OshiLife/Views/LiveEditorView.swift`
- `OshiLife/Views/ManualXImportView.swift`
- `OshiLife/Views/SettingsView.swift`
- reusable UI under `OshiLife/Views/Components/`

You may create new reusable SwiftUI components and a small centralized design-system layer where useful.

Do not invent major new product features that do not currently exist.

In particular, do not add a new tab architecture, global search system, separate calendar product, oshi profile system, or ticket inventory system unless that functionality already exists in the current implementation.

## Preserve Existing Behavior

Do not break or unnecessarily modify:

- SwiftData models or migrations
- persistence formats
- `LiveStore`
- `ImageStore`
- import storage
- X import clients/parsers
- App Group behavior
- URL handoff
- Share Extension ingestion
- existing navigation and sheet flows
- existing localization keys
- existing editor/import functionality

Avoid modifying non-UI logic unless a minimal change is strictly required to support the redesigned UI.

Pay particular attention to `LiveListView`, `LiveEditorView`, and `LiveDetailView`, where presentation and behavior are partially coupled.

Preserve existing bindings, callbacks, accessibility identifiers, navigation wiring, sheet behavior, and user-visible capabilities.

## Visual Direction

The finished app should feel closer to an Apple first-party application than a generic custom SwiftUI app.

Design references:

- Apple Calendar
- Apple Wallet
- Apple Maps
- Apple Settings
- modern native SwiftUI
- iOS 27 Liquid Glass

Do not simply imitate screenshots from these apps. Use their information hierarchy, restraint, platform conventions, and interaction philosophy.

### Core Principles

Use:

- strong visual hierarchy
- generous spacing
- clean native typography
- semantic system colors
- native SwiftUI controls
- SF Symbols where appropriate
- system materials
- restrained accent usage
- subtle depth
- clear content grouping
- native interaction patterns

Avoid:

- excessive rounded-card stacking
- excessive borders
- excessive shadows
- excessive gradients
- excessive blur
- decorative glass on every content surface
- web-dashboard aesthetics
- Material Design aesthetics
- custom controls where native controls are more appropriate

Do not interpret “iOS 27” as “put glass on everything.”

Separate interface chrome from content.

Use Liquid Glass / material effects primarily where appropriate for interface chrome such as:

- navigation controls
- toolbars
- floating controls
- sheets
- overlays
- menus

Keep primary content areas cleaner and easier to read.

## Home / LiveListView

Preserve the current home/card mode and list mode behavior.

Redesign the home presentation so that the next/upcoming live is clearly the primary visual focus.

Prioritize:

1. next live
2. upcoming lives
3. historical lives

For the primary upcoming event, clearly communicate:

- artist
- event title
- date
- countdown
- venue
- OPEN
- START
- status

Use typography, spacing, scale, imagery, and restrained accent treatment to create hierarchy.

Upcoming and historical events should have lower visual priority.

Avoid presenting every event as an equally heavy rounded card.

Preserve existing:

- filtering
- carousel behavior
- countdown behavior
- navigation
- add/edit/import sheets
- lifecycle refresh
- pending import handling
- custom URL intake
- home/list switching

You may reorganize the UI implementation into reusable components if this improves clarity without changing behavior.

## Live Detail

Redesign `LiveDetailView` into a clean Apple-style detail experience.

Create clear visual hierarchy for the existing content:

- cover
- artist/title
- date and schedule
- venue
- map actions
- performers
- ticket options
- notes
- external links
- status/actions

Use native sections, labels, menus, toolbar actions, sheets, and other platform conventions where appropriate.

Secondary actions should not visually compete with the event information.

Preserve all existing content and capabilities.

Preserve existing delete and map behavior.

## Live Editor

Redesign `LiveEditorView` and its host presentations using a cleaner native Form / Section / Sheet structure.

Preserve every existing:

- editable field
- validation rule
- PhotosPicker integration
- venue picker flow
- imported-data merge behavior
- retry behavior
- duplicate handling
- save behavior
- discard behavior

Do not simplify the interface by removing functionality.

Improve information grouping and reduce visual clutter while retaining the complete editor capability.

## Manual X Import

Keep the current X URL import implementation and behavior unchanged.

Redesign only its presentation so it feels native, compact, and visually consistent with the rest of OshiLife.

Preserve:

- clipboard suggestion
- X URL validation
- asynchronous import
- loading state
- error state
- handoff into the existing import editor flow

Do not rewrite the import/network layer as part of this task.

## Settings

Redesign `SettingsView` using Apple Settings-style conventions.

Prefer native:

- Form
- Section
- Picker
- Toggle
- NavigationLink
- LabeledContent

where appropriate.

Preserve the existing settings and About information.

Do not add settings for functionality that does not exist.

Avoid unnecessary custom cards or decorative surfaces.

## Venue Picker

Preserve the existing MapKit search behavior and `VenueSearchService`.

Redesign the search/results presentation to feel closer to native Apple Maps/Search interaction patterns.

Do not rewrite the underlying venue-search logic.

## Shared Components & Design System

Create a small centralized SwiftUI design system where it materially improves consistency.

Use semantic reusable definitions/components for things such as:

- spacing
- typography
- corner radius
- materials
- accent usage
- section styling
- event presentation
- status presentation

Reuse existing components where appropriate and refactor them if necessary.

Prefer system colors, materials, typography, SF Symbols, and native controls over custom equivalents.

Do not over-engineer the design system or introduce unnecessary abstraction layers.

## Color & Accent

Keep the overall interface primarily system-native.

Use accent color selectively for:

- selected states
- important actions
- status
- small highlights
- subtle event emphasis

Do not tint entire screens or every component.

Support Light Mode and Dark Mode naturally through semantic system colors and materials.

Do not implement Dark Mode as simple color inversion.

## Motion

Use restrained native-feeling SwiftUI animation only where it improves interaction.

Prefer subtle:

- spring transitions
- content transitions
- matched transitions where appropriate
- fades
- small scale changes
- native sheet/navigation transitions

Do not add decorative animation, particles, exaggerated bouncing, or game-like motion.

Do not spend excessive implementation time on animation if it does not materially improve the UI.

## Implementation Rules

Do not output a design proposal.

Do not output a refactor plan.

Do not stop and ask for confirmation.

Do not create mockups instead of implementing the UI.

Do not perform unrelated refactors.

Do not rewrite working business logic.

Do not add major features outside the current product scope.

Do not perform extensive manual visual verification.

Do not spend time on exhaustive checks that can be performed manually later.

Perform only the minimum local checks necessary to avoid obvious syntax or code errors.

Fix obvious errors caused directly by your modifications.

Do not expand the task into unrelated pre-existing bugs.

## Git Workflow

Before modifying code:

1. Check the current working tree only to avoid accidentally overwriting unrelated existing changes.
2. Create and switch to a new local branch:

`refactor/ios27-ui`

3. Perform the entire UI refactor on this branch.

Do not:

- commit changes
- push anything
- perform remote Git operations
- modify the primary branch
- merge branches
- create a pull request
- create or modify GitHub Actions workflows
- wait for or inspect CI

Leave all completed modifications **uncommitted** in the local working tree on `refactor/ios27-ui`.

Do not revert, stash, discard, or clean the completed changes.

I will review, commit, and push them manually.

## Completion

Once the complete existing UI has been refactored and the minimum necessary local code checks are complete, stop.

Final response should contain only:

- current branch
- major UI areas changed
- any important issue requiring my attention

Keep the final response brief. Do not provide a long implementation report.
