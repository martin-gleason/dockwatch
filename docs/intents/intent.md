# Intent: a menu bar tool that logs the Thunderbolt dock and keeps it from falling asleep

**Author:** Marty Gleason, owner, with Turing
**Status:** `draft`
**Date:** 2026-10-18

> **This is a proto-spec, not a spec.** It records what is wanted, why, and under which constraints, before anything is designed. It is a baseline and is not updated to match reality.

---

## Problem

The Razer Thunderbolt 4 Dock Chroma on the owner's M1 Max MacBook Pro "powers down" and then some of its attached devices come back and some do not. Usually the USB-SATA drive enclosures drop while the keyboard keeps working; sometimes it is the reverse. Nothing in macOS says which device dropped, when, or in what order, and the past cannot be reconstructed from the system log because kernel USB events are not logged at the default level and disk arbitration redacts the disk names.

An investigation on 2026-10-18 found the mechanism. The dock is the Mac's charger. Whenever the Mac enters deep idle sleep, the dock's power-delivery contract drops within a few seconds, which dark-wakes the Mac; it sleeps again and the loop repeats every minute or two. The power log holds about 920 of these in eight days. The dock's hubs are suspended and resumed on every cycle, and the drive bridges are the devices least able to survive that.

## Proposed outcome

A small menu bar app that does two things. It records every dock-related event (device, volume, sleep, wake, charger) to a file and shows the recent ones in the menu, so the next drop is explained instead of guessed at. And it offers a switch that, while the dock is attached, keeps the Mac out of idle sleep, so the loop that causes the drops never starts. The display still sleeps. If the switch is on and the charger-detach count goes to zero, the mechanism is confirmed; if it does not, the log says what happened instead.

## Affected users and systems

One user, one Mac, one dock. Touches IOKit (USB device notifications and power assertions), DiskArbitration (volumes), the power management root domain (sleep and wake), and UserNotifications. Coexists with a shell-script monitor already running as a LaunchAgent at `~/dockwatch`, which stays as the reference instrument until the app's log is shown to agree with it.

## Constraints

- Due end of day 2026-10-18.
- Swift, SwiftPM, AppKit, macOS 14+, no third-party dependencies, mirroring HueBar, the owner's other menu bar app.
- No root, no kernel or system extension. There is no API to control the dock's power controller; the tool must not claim to.
- The owner reviews every PR and does not write Swift.

## Open questions

1. Is the one-sentence vision right as written? (`O1`)
2. Learning level: 5% proposed because of the deadline. (`O2`)
3. Is holding the Mac awake around the clock while docked acceptable, or should a schedule window be in the MVP rather than v1.1? (`O3`)
4. Does the app replace the shell monitor once its log agrees, or do both run? (`O5`)

## Framings rejected

- **"A sleep blocker"** (an Amphetamine clone). Rejected: it would hold the Mac awake whether or not the dock is there, and it throws away the log, which is half the value.
- **"A drive guardian"** (a Jettison clone that ejects before sleep). Rejected: the symptom also hits the keyboard chain, and ejecting hides the diagnosis.
- **"A dock power-cycler."** Rejected: impossible from user space on macOS.
- **"A general USB event logger."** Rejected: too broad; everything here is about one dock, and the dock's presence is what gates the hold.

-----
2026-10-18

#AI/Claude
