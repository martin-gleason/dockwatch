// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 11:40 -05:00
// F1-T4 — wires USBMonitor → DockTracker → the status item (FR1, FR2).
import AppKit
import DockCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController!
    private var monitor: USBMonitor!
    private var tracker = DockTracker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController()
        statusItem.render(state: tracker.state, held: false)
        monitor = USBMonitor { [weak self] event in self?.handle(event) }
        do {
            try monitor.start()
        } catch {
            // No fourth icon state (FR1 names three); the failure is said in the menu.
            statusItem.showProblem("USB monitor failed to start: \(error)")
            log("USBMonitor.start failed: \(error)")
        }
    }

    private func handle(_ event: USBEvent) {
        // F2 replaces this stderr line with the EventStore (FR3).
        log("usb.\(event.kind.rawValue) \(event.device.summary)")
        if tracker.apply(event) {
            statusItem.render(state: tracker.state, held: false)
            log("dock → \(tracker.state.rawValue)")
        }
    }
}

/// stderr, timestamped. Kept until F2's EventStore exists.
func log(_ line: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    FileHandle.standardError.write(Data("\(ts) \(line)\n".utf8))
}
