// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 16:54 -05:00
// F1-T4 / F2-T4 / F3-T3 / F5-T2 / F6-T3 — the menu bar icon and its menu (FR1, FR5, FR7, FR8, FR9).
import AppKit
import DockCore

/// One row of the eject section, as the app delegate describes it.
struct EjectEntry {
    let bsdName: String
    let title: String
    /// A recent result to show beside the name, if any.
    let status: String?
    /// False for a just-ejected volume that is listed only so its result can be read.
    let isEjectable: Bool
}

final class StatusItemController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let stateLine = NSMenuItem(title: "Dock: unknown", action: nil, keyEquivalent: "")
    private let problemLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let keepAwakeItem = NSMenuItem(title: "Keep Dock Awake", action: #selector(toggleKeepAwake), keyEquivalent: "k")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let ejectHeader = NSMenuItem(title: "Dock Volumes", action: nil, keyEquivalent: "")
    private let countersLine = NSMenuItem(title: "Last 24 h: —", action: nil, keyEquivalent: "")
    private let timelineItem = NSMenuItem(title: "Recent Events", action: nil, keyEquivalent: "")
    private let timelineMenu = NSMenu()
    private static let ejectTag = 900

    /// FR8 — set by the app delegate; reveals the log file.
    var onOpenLog: (() -> Void)?
    /// FR5 — set by the app delegate; flips the hold toggle.
    var onToggleKeepAwake: (() -> Void)?
    /// FR7 — set by the app delegate; flips launch at login.
    var onToggleLaunchAtLogin: (() -> Void)?
    /// FR4 — the counters line and the recent-event lines, asked for each time the menu opens.
    var countersText: (() -> String)?
    var timelineLines: (() -> [String])?
    /// FR9 — the volumes on the dock right now, asked for each time the menu opens.
    var ejectEntries: (() -> [EjectEntry])?
    /// FR9 — eject one volume by BSD name, or all of them.
    var onEject: ((String) -> Void)?
    var onEjectAll: (() -> Void)?

    override init() {
        super.init()
        // Every isEnabled in this file is authoritative; AppKit would otherwise re-enable any
        // item whose target answers its action each time the menu opens (F5 review, finding 3).
        menu.autoenablesItems = false
        stateLine.isEnabled = false
        problemLine.isEnabled = false
        problemLine.isHidden = true
        ejectHeader.isEnabled = false
        menu.addItem(stateLine)
        menu.addItem(problemLine)
        countersLine.isEnabled = false
        countersLine.toolTip = "Devices and volumes lost from the dock, charger drops, and full wakes in the last 24 hours. Charger drops during sleep are in the system power log (pmset -g log), not here."
        menu.addItem(countersLine)
        timelineItem.submenu = timelineMenu
        menu.addItem(timelineItem)
        menu.addItem(.separator())
        keepAwakeItem.target = self
        keepAwakeItem.toolTip = "While on and the dock is attached, the Mac does not idle-sleep. The display still sleeps."
        menu.addItem(keepAwakeItem)
        menu.addItem(.separator())
        menu.addItem(ejectHeader)
        // The eject rows are inserted after the header on each open (menuNeedsUpdate).
        menu.addItem(.separator())
        let open = NSMenuItem(title: "Open Log", action: #selector(openLog), keyEquivalent: "l")
        open.target = self
        menu.addItem(open)
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DockWatch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self
        item.menu = menu
    }

    // MARK: FR9 — rebuilt when the menu opens, never on a timer (NFR2)

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === self.menu else { return }
        // FR4: counters and the timeline, computed on open.
        countersLine.title = countersText?() ?? "Last 24 h: —"
        timelineMenu.removeAllItems()
        let lines = timelineLines?() ?? []
        if lines.isEmpty {
            let none = NSMenuItem(title: "No events yet", action: nil, keyEquivalent: "")
            none.isEnabled = false
            timelineMenu.addItem(none)
        }
        for line in lines {
            let row = NSMenuItem(title: line, action: nil, keyEquivalent: "")
            row.isEnabled = false
            row.attributedTitle = NSAttributedString(string: line, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)])
            timelineMenu.addItem(row)
        }
        for existing in menu.items where existing.tag == Self.ejectTag { menu.removeItem(existing) }
        let entries = ejectEntries?() ?? []
        var index = menu.index(of: ejectHeader) + 1
        func insert(_ row: NSMenuItem) {
            row.tag = Self.ejectTag
            menu.insertItem(row, at: index)
            index += 1
        }
        if entries.isEmpty {
            let none = NSMenuItem(title: "No volumes on the dock", action: nil, keyEquivalent: "")
            none.isEnabled = false
            none.indentationLevel = 1
            insert(none)
            return
        }
        if entries.filter(\.isEjectable).count > 1 {
            let all = NSMenuItem(title: "Eject All Dock Volumes", action: #selector(ejectAll), keyEquivalent: "e")
            all.target = self
            all.indentationLevel = 1
            insert(all)
        }
        for entry in entries {
            let row = NSMenuItem(title: entry.isEjectable ? "Eject “\(entry.title)”" : "“\(entry.title)”",
                                 action: entry.isEjectable ? #selector(ejectOne(_:)) : nil, keyEquivalent: "")
            row.target = entry.isEjectable ? self : nil
            row.isEnabled = entry.isEjectable
            row.representedObject = entry.bsdName
            row.indentationLevel = 1
            if let status = entry.status {
                if #available(macOS 14.4, *) { row.subtitle = status } else { row.title += " — \(status)" }
            }
            insert(row)
        }
    }

    @objc private func ejectOne(_ sender: NSMenuItem) {
        if let bsd = sender.representedObject as? String { onEject?(bsd) }
    }

    @objc private func ejectAll() { onEjectAll?() }
    @objc private func openLog() { onOpenLog?() }
    @objc private func toggleLaunchAtLogin() { onToggleLaunchAtLogin?() }

    /// FR7: checkmark follows the system's answer; greyed when there is no bundle to register.
    func setLaunchAtLogin(on: Bool, available: Bool) {
        loginItem.state = on ? .on : .off
        loginItem.isEnabled = available
    }
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
