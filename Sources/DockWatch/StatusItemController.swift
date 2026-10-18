// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 11:55 -05:00
// F1-T4 / F2-T4 — the menu bar icon and its menu (FR1, FR8). Three states; "held" is wired in F3.
import AppKit
import DockCore

final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let stateLine = NSMenuItem(title: "Dock: unknown", action: nil, keyEquivalent: "")
    private let problemLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    /// FR8 — set by the app delegate; reveals the log file.
    var onOpenLog: (() -> Void)?

    override init() {
        super.init()
        let menu = NSMenu()
        stateLine.isEnabled = false
        problemLine.isEnabled = false
        problemLine.isHidden = true
        menu.addItem(stateLine)
        menu.addItem(problemLine)
        menu.addItem(.separator())
        let open = NSMenuItem(title: "Open Log", action: #selector(openLog), keyEquivalent: "l")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DockWatch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    @objc private func openLog() { onOpenLog?() }

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
