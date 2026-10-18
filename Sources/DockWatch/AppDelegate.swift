// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 12:15 -05:00
// F1-T4 / F2-T4 — wires the monitors to the tracker, the store and the status item (FR1–FR3, FR8).
import AppKit
import DockCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController!
    private var usb: USBMonitor!
    private var volumes: VolumeMonitor!
    private var sleep: SleepMonitor!
    private var power: PowerMonitor!
    private var tracker = DockTracker()
    private let store = EventStore(directory: EventStore.defaultDirectory())

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController()
        statusItem.onOpenLog = { [store] in NSWorkspace.shared.activateFileViewerSelecting([store.url]) }
        statusItem.render(state: tracker.state, held: false)

        usb = USBMonitor { [weak self] in self?.handle($0) }
        volumes = VolumeMonitor { [weak self] in self?.handle($0) }
        sleep = SleepMonitor { [weak self] in self?.handle($0) }
        power = PowerMonitor { [weak self] in self?.handle($0) }
        start("USB monitor") { try usb.start() }
        start("volume monitor") { try volumes.start() }
        start("sleep monitor") { try sleep.start() }
        start("power monitor") { try power.start() }
    }

    private func start(_ name: String, _ body: () throws -> Void) {
        do { try body() } catch {
            // No fourth icon state (FR1 names three); the failure is said in the menu.
            statusItem.showProblem("\(name) failed to start: \(error)")
            log("\(name) failed to start: \(error)")
        }
    }

    // MARK: events → store

    private func record(_ event: Event) {
        if store.append(event) {
            statusItem.clearProblem()
        } else {
            statusItem.showProblem("Log: \(store.lastError ?? "unknown failure")")
        }
        log("\(event.kind.rawValue) \(event.subject) \(event.detail.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))")
    }

    private func handle(_ e: USBEvent) {
        var detail = ["vendor": String(format: "0x%04x", e.device.vendorID),
                      "product": String(format: "0x%04x", e.device.productID),
                      "location": String(format: "0x%08x", e.device.locationID)]
        if e.initial { detail["initial"] = "true" }
        record(Event(kind: e.kind == .attached ? .usbAttached : .usbDetached,
                     subject: e.device.productName ?? String(format: "%04x:%04x", e.device.vendorID, e.device.productID),
                     detail: detail))
        if tracker.apply(e) {
            statusItem.render(state: tracker.state, held: false)
        }
    }

    private func handle(_ e: VolumeEvent) {
        let kind: Event.Kind
        switch e.kind {
        case .mounted: kind = .volumeMounted
        case .unmounted: kind = .volumeUnmounted
        case .disappeared: kind = .volumeDisappeared
        }
        var detail = ["bsd": e.volume.bsdName]
        if let p = e.volume.path { detail["path"] = p }
        if let p = e.volume.protocolName { detail["protocol"] = p }
        if let m = e.volume.model { detail["model"] = m }
        if let l = e.volume.usbLocationID { detail["usbLocation"] = String(format: "0x%08x", l) }
        if e.initial { detail["initial"] = "true" }
        record(Event(kind: kind, subject: e.volume.name, detail: detail))
    }

    private func handle(_ e: SleepEvent) {
        let kind: Event.Kind
        switch e.kind {
        case .willSleep: kind = .systemSleep
        case .wake: kind = .systemWake
        }
        record(Event(kind: kind, subject: "system"))
    }

    private func handle(_ e: PowerEvent) {
        var detail: [String: String] = ["source": e.state.source]
        if let w = e.state.watts { detail["watts"] = String(w) }
        if let w = e.previousWatts, !e.state.external { detail["lastWatts"] = String(w) }
        if e.initial { detail["initial"] = "true" }
        record(Event(kind: e.state.external ? .powerConnected : .powerDisconnected, subject: e.state.source, detail: detail))
    }
}

/// stderr mirror of the log, for development runs. Uses the store's formatter.
func log(_ line: String) {
    FileHandle.standardError.write(Data("\(EventLine.timestamp.string(from: Date())) \(line)\n".utf8))
}
