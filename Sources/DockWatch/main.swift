// Created: 2026-10-18 11:25 -05:00 · Edited: 2026-10-18 11:40 -05:00
// F1-T1 — entry point. A menu bar accessory: no Dock icon, no main window.
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
