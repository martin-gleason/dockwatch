// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 11:40 -05:00
// F1-T4 — the menu bar icon and its menu (FR1). Three states; "held" is wired in F3.
import AppKit
import DockCore

final class StatusItemController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let stateLine = NSMenuItem(title: "Dock: unknown", action: nil, keyEquivalent: "")
    private let problemLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    init() {
        let menu = NSMenu()
        stateLine.isEnabled = false
        problemLine.isEnabled = false
        problemLine.isHidden = true
        menu.addItem(stateLine)
        menu.addItem(problemLine)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DockWatch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    /// FR1: docked and held awake · docked, not held · not docked.
    func render(state: DockState, held: Bool) {
        let (symbol, text): (String, String)
        switch (state, held) {
        case (.docked, true):  (symbol, text) = ("cable.connector.horizontal", "Dock: connected, kept awake")
        case (.docked, false): (symbol, text) = ("cable.connector", "Dock: connected")
        case (.undocked, _):   (symbol, text) = ("cable.connector.slash", "Dock: not connected")
        }
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: text) {
            image.isTemplate = true
            item.button?.image = image
            item.button?.title = ""
        } else {
            item.button?.image = nil
            item.button?.title = state == .docked ? "⚡︎" : "–"
        }
        item.button?.toolTip = text
        stateLine.title = text
    }

    func showProblem(_ text: String) {
        problemLine.title = text
        problemLine.isHidden = false
    }
}
