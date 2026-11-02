# Lock Screen Checklist (iOS)

A small SwiftUI app plus a WidgetKit extension that lets you **tick checklist items straight from the iPhone Lock Screen**, without unlocking or opening the app.

## What you get

| Where | Widget / control | What a tap does |
|---|---|---|
| Lock Screen, rectangular | Up to 3 items (unfinished first) | Ticks / unticks that item. When all are done, "Tap to reset". |
| Lock Screen, circular | Progress ring `2/5` | Ticks the next unfinished item |
| Lock Screen, inline (above clock) | "Next: …" | Display only (iOS doesn't make inline widgets interactive) |
| Lock Screen bottom corners / Control Center (iOS 18+) | "Tick Next" control | Ticks the next unfinished item |
| Home Screen small / medium / large | 4–10 items | Ticks / unticks that item |
| Siri / Shortcuts / Action button | "Tick next item", "Reset checklist" | Same as above |

The app is where you add, delete, reorder and reset items. The list is stored as JSON in a shared App Group container. The file uses `completeUntilFirstUserAuthentication` protection, so the widget can still read and write it while the phone is locked.

## Requirements

- Xcode 16+ (Xcode 15 works if you remove the iOS 18 `TickNextControl`)
- iOS 17+ device or simulator (interactive widgets need iOS 17)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to generate the project

## Build & run

```bash
cd ios-lockscreen-checklist
xcodegen generate
open LockChecklist.xcodeproj
```

1. In **Signing & Capabilities**, pick your team for both targets (`LockChecklist` and `LockChecklistWidget`).
2. If `com.example.lockchecklist` is taken, change the bundle IDs in `project.yml` and the App Group ID in **three** places: `Shared/ChecklistStore.swift` (`appGroupID`), `App/App.entitlements` and `Widget/Widget.entitlements`.
3. Run the `LockChecklist` scheme on your iPhone and add some items.
4. Lock the phone, long-press the Lock Screen → **Customize** → **Lock Screen** → tap the widget area → add **Checklist** (rectangular or circular).
5. Tap an item on the Lock Screen and it's ticked.

## Project layout

```
ios-lockscreen-checklist/
├── project.yml                  # XcodeGen spec (app + widget extension)
├── Shared/                      # compiled into both targets
│   ├── ChecklistStore.swift     # model + App Group persistence + widget reload
│   └── ChecklistIntents.swift   # ToggleItem / TickNext / Reset App Intents + Siri shortcuts
├── App/
│   ├── LockChecklistApp.swift
│   ├── ContentView.swift        # add / edit / reorder / reset list
│   └── App.entitlements
└── Widget/
    ├── ChecklistWidget.swift    # Lock Screen + Home Screen widget, iOS 18 control, bundle
    └── Widget.entitlements
```

## How the Lock Screen tick works

`Button(intent: ToggleItemIntent(itemID:))` inside the widget runs the App Intent in the widget extension's process. The intent updates the shared JSON file and calls `WidgetCenter.shared.reloadAllTimelines()`, and the widget redraws with the item ticked. `authenticationPolicy = .alwaysAllowed` means Face ID isn't required. If you'd rather require it, change it to `.requiresAuthentication`.

## Ideas to extend

- Daily auto-reset: store a `lastReset` date and clear ticks on the first load of a new day.
- Multiple lists: make the widget an `AppIntentConfiguration` with a list picker.
- iCloud sync with `NSUbiquitousKeyValueStore` or CloudKit.
