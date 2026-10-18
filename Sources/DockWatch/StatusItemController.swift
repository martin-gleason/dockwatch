// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 12:41 -05:00
// F1-T4 / F2-T4 / F3-T3 — the menu bar icon and its menu (FR1, FR5, FR8). Three icon states.
import AppKit
import DockCore

final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let stateLine = NSMenuItem(title: "Dock: unknown", action: nil, keyEquivalent: "")
    private let problemLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let keepAwakeItem = NSMenuItem(title: "Keep Dock Awake", action: #selector(toggleKeepAwake), keyEquivalent: "k")

    /// FR8 — set by the app delegate; reveals the log file.
    var onOpenLog: (() -> Void)?
    /// FR5 — set by the app delegate; flips the hold toggle.
    var onToggleKeepAwake: (() -> Void)?

    override init() {
        super.init()
        let menu = NSMenu()
        stateLine.isEnabled = false
        problemLine.isEnabled = false
        problemLine.isHidden = true
        menu.addItem(stateLine)
        menu.addItem(problemLine)
        menu.addItem(.separator())
        keepAwakeItem.target = self
        keepAwakeItem.toolTip = "While on and the dock is attached, the Mac does not idle-sleep. The display still sleeps."
        menu.addItem(keepAwakeItem)
        let open = NSMenuItem(title: "Open Log", action: #selector(openLog), keyEquivalent: "l")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DockWatch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    @objc private func openLog() { onOpenLog?() }
    @objc private func toggleKeepAwake() { onToggleKeepAwake?() }

    func setKeepAwake(on: Bool) {
        keepAwakeItem.state = on ? .on : .off
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

    /// A transient failure must not read as current forever (F2 review).
    func clearProblem() {
        problemLine.isHidden = true
    }
}
