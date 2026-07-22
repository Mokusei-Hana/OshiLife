# OshiLife iOS App

## Overview

OshiLife is an iOS app for managing personal idol activities (推し活).

The goal is to help users save and organize Live/Event information from X posts and display them as beautiful cards.

This is NOT an event aggregation service.

The app should feel like a personal 推し活 diary, not a normal calendar application.

---

# Tech Stack

- Swift
- SwiftUI
- SwiftData
- MVVM
- iOS 26+

The app should adopt the latest iOS design language, including Liquid Glass design principles where appropriate.

Use native Apple frameworks whenever possible.

---

# Architecture

Use simple MVVM.

Structure:

App
Models
Views
ViewModels
Services
ShareExtension


Flow:

View
 ↓
ViewModel
 ↓
Service
 ↓
SwiftData


Avoid unnecessary abstraction.

---

# MVP Features

## Live Management

Users can create and manage Live events.

Live fields:

- id
- artist/group name
- title
- date
- startTime
- venue
- address
- coverImage
- ticketURL
- sourceURL
- notes
- status


Status:

- planned
- attended
- cancelled


---

## Live Card UI

The main UI should focus on beautiful Live cards.

Card contains:

- cover image
- event title
- date
- venue
- status


Design inspiration:

- Apple Wallet
- Apple Music cards
- modern diary apps
- iOS 26 Liquid Glass design language


Prioritize:
- animation
- spacing
- typography
- premium feeling

Use:
- glass materials
- translucent surfaces
- layered depth
- smooth transitions

---

## Live Detail

Show:

- cover image
- information
- map button
- ticket link
- source URL
- notes

Use MapKit for location.


---

# X Share Import

Implement Share Extension.

User flow:

X
↓
Share
↓
OshiLife
↓
Receive tweet URL
↓
Fetch X oEmbed
↓
Create draft Live
↓
User confirms


Use:

https://publish.x.com/oembed?url=

Do NOT use X API.


Imported data:

- author
- tweet text
- tweet URL


Images:

Download tweet media image as cover image.

The import result should always be editable by the user.

No OCR.
No timetable recognition.


---

# Image Storage

Do not store image binary in SwiftData.

Save images in App Sandbox.

Store only image path in database.


---

# Not included in MVP

Do not implement:

- backend server
- user account
- cloud sync
- AI parsing
- timetable OCR
- social/community features


---

# Development Rules

Before coding:

1. Analyze current project.
2. Explain implementation plan.
3. Implement incrementally.

Do not generate the whole app at once.

Keep code clean and maintainable.


---

# Future Considerations

Possible future features:

- iCloud sync
- Home Screen Widget
- Live Activity
- Apple Calendar integration
- Cheki/photo records