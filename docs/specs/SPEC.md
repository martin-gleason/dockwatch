# DockWatch — SPEC

DockWatch is a native Mac Menu Bar tool that logs the activity of the thunderbolt 4 dock, keeps it from falling asleep, and lets you eject or remove connected devices quickly and safely.

Created: 2026-10-18 10:55 -05:00 · Edited: 2026-10-18 11:50 -05:00

> **Vision sentence status: ratified. The owner's own rewrite of 2026-10-18 (D11), pasted here on the owner's instruction; the original agent-reduced sentence is in git history.**

## What "falling asleep" means here

The investigation that preceded this project (2026-10-18, this Mac, Razer Thunderbolt 4 Dock Chroma, firmware 38.1) established the mechanism the tool targets. Every one of roughly 920 recorded charger-detach events in eight days happened while the Mac was in deep idle sleep: the Mac sleeps, 3 to 4 seconds later the dock's power-delivery contract drops, the Mac dark-wakes for about 45 seconds, sleeps again, and the loop repeats every 1 to 2 minutes around the clock. Attached devices drop after enough suspend/resume cycles, unevenly between the dock's USB 2 and USB 3 hub chains. **"Keeping the dock awake" therefore means keeping the Mac out of idle system sleep while the dock is attached.** The display may still sleep. No user-space API can touch the dock's own power controller, and this spec does not pretend otherwise.

## Functional requirements

| ID | Requirement |
|---|---|
| FR1 | The menu bar icon shows the dock state at a glance, in three states: docked and held awake · docked, not held · not docked. |
| FR2 | The dock is recognised by its USB vendor and product ID (default: Razer `0x1532:0x122E`, the device named "Thunderbolt 4 Dock"), detected at launch and on every attach or detach, without polling. |
| FR3 | Every USB device attach and detach, every external volume mount, unmount and unexpected disappearance, every system sleep, dark wake and wake, and every charger connect and disconnect (with negotiated watts) is recorded with a timestamp to an append-only log file. |
| FR4 | The menu shows the most recent events (at least 20) and four rolling 24-hour counters: devices lost, volumes lost, charger drops, wakes. |
| FR5 | A "Keep dock awake" toggle. While it is on and the dock is present, the app holds a system idle-sleep-prevention assertion that leaves display sleep untouched. The assertion is released within 5 seconds of the dock leaving or the toggle turning off, is re-asserted after a wake if the dock is still present, and the toggle's state survives relaunch. |
| FR6 | When a device or volume disappears while the Mac is awake, the user gets a notification naming it. |
| FR7 | A "Launch at login" toggle. |
| FR8 | An "Open log" action that reveals the log file in Finder. |
| FR9 | Any volume on a disk attached through the dock can be ejected from the menu, singly or all at once, and the result is reported: done, or blocked and by what. No macOS API ejects a device without storage; for those, "remove" means the log confirms the device is gone, and the menu never offers an action it cannot perform. (Added by D11.) |

## Non-functional requirements

| ID | Requirement |
|---|---|
| NFR1 | No root, no kernel or system extension, no private API. Everything goes through public IOKit, DiskArbitration, IOPMLib, ServiceManagement and UserNotifications. |
| NFR2 | Event-driven. Device, volume, power and sleep state arrive through system callbacks; there are no polling timers. |
| NFR3 | Resident memory under 30 MB at idle. AppKit only; no SwiftUI. |
| NFR4 | No third-party dependencies. |
| NFR5 | macOS 14 or later on Apple silicon. Intel is not verified (the owner has no Intel Mac). |
| NFR6 | The log is JSON Lines, one event per line, opened for append, rotated at 20 MB keeping one previous file. An unwritable log never crashes the app; it surfaces in the menu. |
| NFR7 | `DockCore` never imports AppKit. The hold policy, dock matcher, event model and event queries are pure and unit-tested offline. |
| NFR8 | The app survives sleep and wake: every subscription is re-armed and the hold state is re-evaluated on wake. |

## Stack

Baseline. Changing any of this is a `D<n>`.

- language: Swift 5.9 language mode on the Swift 6.4 toolchain (Xcode 27.1)
- framework: AppKit, no SwiftUI; SwiftPM package, no Xcode project; macOS 14 or later; no third-party dependencies
- runner: `swift test` (XCTest)
- layout: `Sources/DockCore` (library, no AppKit) · `Sources/DockWatch` (executable) · `Tests/DockCoreTests`
- ci: GitHub Actions on macOS once the repository is pushed; `.githooks/pre-commit` locally until then

## Hook intentions

- Every FR has a test or a named manual check, recorded in the feature plan with its evidence.
- `swift test` is the harness; offline tests pass on every change.
- Every mutation row in the register names the test that catches it, and the row says `run` only after that test was seen red.

## Out of scope for MVP (future milestones, enter via `D<n>`)

Eject-before-sleep and remount-on-wake · auto-remount of a volume that reappears unmounted · a schedule window for the hold · a dock picker UI for non-Razer docks · per-port hub power cycling (uhubctl, unverified on this dock) · Chroma lighting · dock firmware · charts or exports beyond the log file · multiple docks · Intel verification.

## What this is not

Not a general sleep blocker: the hold exists only while the dock is present. Not a drive guardian: unmounting drives before sleep treats one symptom and loses the diagnosis. Not a dock power-cycler: there is no API for that. Not a USB event logger for everything: it is about one dock.
