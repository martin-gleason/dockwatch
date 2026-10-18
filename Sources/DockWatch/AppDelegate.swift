// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 13:55 -05:00
// F1-T4 / F2-T4 / F3-T3 / F6-T3 — wires the monitors to the tracker, the store, the hold, the ejector and the status item.
import AppKit
import DockCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let keepAwakeKey = "keepDockAwake"
    /// How long an eject result stays beside the volume in the menu.
    static let ejectResultLifetime: TimeInterval = 60

    private var statusItem: StatusItemController!
    private var usb: USBMonitor!
    private var volumes: VolumeMonitor!
    private var sleep: SleepMonitor!
    private var power: PowerMonitor!
    private var tracker = DockTracker()
    private var policy = HoldPolicy()
    private let assertion = AssertionController()
    private let ejector = VolumeEjector()
    private let store = EventStore(directory: EventStore.defaultDirectory())
    private var ejectMenu = EjectMenuModel(lifetime: AppDelegate.ejectResultLifetime)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController()
        statusItem.onOpenLog = { [store] in NSWorkspace.shared.activateFileViewerSelecting([store.url]) }
        statusItem.onToggleKeepAwake = { [weak self] in self?.toggleKeepAwake() }
        statusItem.ejectEntries = { [weak self] in self?.ejectEntries() ?? [] }
        statusItem.onEject = { [weak self] bsd in self?.eject(bsdName: bsd) }
        statusItem.onEjectAll = { [weak self] in self?.ejectAll() }

        // D10: off until the owner turns it on; the choice then survives relaunch (FR5).
        let toggle = UserDefaults.standard.bool(forKey: Self.keepAwakeKey)
        policy = HoldPolicy(toggle: toggle, docked: false)
        statusItem.setKeepAwake(on: toggle)
        render()

        usb = USBMonitor { [weak self] in self?.handle($0) }
        volumes = VolumeMonitor { [weak self] in self?.handle($0) }
        sleep = SleepMonitor { [weak self] in self?.handle($0) }
        power = PowerMonitor { [weak self] in self?.handle($0) }
        start("USB monitor") { try usb.start() }
        start("volume monitor") { try volumes.start() }
        start("sleep monitor") { try sleep.start() }
        start("power monitor") { try power.start() }
        start("ejector") { try ejector.start() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        apply(HoldPolicy.Decision(hold: false, reapply: false))
    }

    private func start(_ name: String, _ body: () throws -> Void) {
        do { try body() } catch {
            // No fourth icon state (FR1 names three); the failure is said in the menu.
            statusItem.showProblem("\(name) failed to start: \(error)")
            log("\(name) failed to start: \(error)")
        }
    }

    // MARK: the hold (FR5)

    private func toggleKeepAwake() {
        let on = !policy.toggle
        UserDefaults.standard.set(on, forKey: Self.keepAwakeKey)
        statusItem.setKeepAwake(on: on)
        apply(policy.apply(.toggleChanged(on)))
    }

    /// Puts the policy's answer into force and logs a change of hold state (D21).
    private func apply(_ decision: HoldPolicy.Decision) {
        let before = assertion.isHeld
        let ok = assertion.set(held: decision.hold, reapply: decision.reapply)
        if !ok { statusItem.showProblem("Sleep assertion: \(assertion.lastError ?? "unknown failure")") }
        if assertion.isHeld != before || (decision.reapply && assertion.isHeld) {
            record(Event(kind: assertion.isHeld ? .holdOn : .holdOff, subject: AssertionController.name,
                         detail: decision.reapply ? ["reapplied": "true"] : [:]))
        }
        render()
    }

    private func render() {
        statusItem.render(state: tracker.state, held: assertion.isHeld)
    }

    // MARK: eject (FR9)

    /// Mounted external volumes whose disk hangs off the dock's USB controller.
    private func dockVolumes() -> [VolumeInfo] {
        guard let dock = tracker.dockLocationID else { return [] }
        return volumes.mountedVolumes.filter { v in
            guard let loc = v.usbLocationID else { return false }
            return DockMembership.isOnDock(usbLocationID: loc, dockLocationID: dock)
        }
    }

    private func ejectEntries() -> [EjectEntry] {
        ejectMenu.rows(mounted: dockVolumes().map { (bsdName: $0.bsdName, title: $0.name) })
            .map { EjectEntry(bsdName: $0.bsdName, title: $0.title, status: $0.status, isEjectable: $0.isEjectable) }
    }

    private func eject(bsdName: String) {
        guard let volume = dockVolumes().first(where: { $0.bsdName == bsdName }) else {
            // The row was built when the menu opened; the volume went away since (F6 review, 5).
            reportEject(bsdName: bsdName, title: bsdName, text: "No longer mounted", done: false)
            return
        }
        do {
            try ejector.eject(bsdName: bsdName, mountPath: volume.path) { [weak self] result in
                self?.reportEject(bsdName: bsdName, title: volume.name, text: result.menuText, done: result.isDone)
            }
        } catch {
            reportEject(bsdName: bsdName, title: volume.name, text: "Could not eject: \(error)", done: false)
        }
    }

    private func reportEject(bsdName: String, title: String, text: String, done: Bool) {
        ejectMenu.record(bsdName: bsdName, title: title, text: text)
        record(Event(kind: .volumeEject, subject: title, detail: ["bsd": bsdName, "result": text, "done": done ? "true" : "false"]))
    }

    private func ejectAll() {
        for volume in dockVolumes() { eject(bsdName: volume.bsdName) }
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
            apply(policy.apply(.dockChanged(tracker.state == .docked)))
        }
    }

    private func handle(_ e: VolumeEvent) {
        let kind: Event.Kind
        switch e.kind {
        case .mounted:
            kind = .volumeMounted
            ejectMenu.volumeMounted(bsdName: e.volume.bsdName)   // a remounted drive never reads "Ejected"
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
        switch e.kind {
        case .willSleep:
            record(Event(kind: .systemSleep, subject: "system"))
        case .wake:
            record(Event(kind: .systemWake, subject: "system"))
            apply(policy.apply(.didWake))   // NFR8: re-assert after a wake
        }
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
