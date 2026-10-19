// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 19:20 -05:00
// F1-T2 — folds USB events into "is the dock here" (FR1, FR2). Pure; no IOKit.

public enum DockState: String, Equatable {
    case docked, undocked
}

public struct DockTracker: Equatable {
    public let identity: DockIdentity
    /// Registry IDs of matching devices currently present. A set, not a flag, so two
    /// matching devices (or a replug that enumerates before the old entry terminates)
    /// cannot leave the tracker saying "undocked" while a dock is still attached.
    private var present: [UInt64: UInt32] = [:]   // registry ID → USB location
    /// The dock's controller as last seen. Kept after the undock so the children that
    /// terminate after the dock device are still judged the dock's (F4b), and forgotten once
    /// nothing remains on that controller, so a later device there is not the dock's
    /// (security review 2026-10-18, finding 5).
    public private(set) var lastKnownDockLocationID: UInt32?
    /// Every other USB device present, registry ID → location: what decides "nothing remains".
    private var others: [UInt64: UInt32] = [:]

    public init(identity: DockIdentity = .razerThunderbolt4Dock) {
        self.identity = identity
    }

    public var state: DockState { present.isEmpty ? .undocked : .docked }

    /// The dock device's USB location while docked; F6 derives "on the dock" from it.
    public var dockLocationID: UInt32? { present.values.min() }

    /// Is this device the dock's? The identifying device always; otherwise anything on the
    /// dock's controller, current or last known (D28, F4b). Nothing before a dock was seen.
    public func isOnDock(_ device: USBDeviceDescriptor) -> Bool {
        if identity.matches(device) { return true }
        guard let dock = dockLocationID ?? lastKnownDockLocationID else { return false }
        return DockMembership.isOnDock(usbLocationID: device.locationID, dockLocationID: dock)
    }

    /// Applies one event. Returns `true` only when `state` changed.
    @discardableResult
    public mutating func apply(_ event: USBEvent) -> Bool {
        guard identity.matches(event.device) else {
            switch event.kind {
            case .attached: others[event.device.registryID] = event.device.locationID
            case .detached: others.removeValue(forKey: event.device.registryID)
            }
            forgetControllerIfEmpty()
            return false
        }
        let before = state
        switch event.kind {
        case .attached:
            present[event.device.registryID] = event.device.locationID
            lastKnownDockLocationID = event.device.locationID
        case .detached:
            present.removeValue(forKey: event.device.registryID)
            forgetControllerIfEmpty()
        }
        return state != before
    }

    /// Undocked and no device left on the remembered controller: forget it. Judged after each
    /// detach is applied, so the last child was still counted before this runs.
    private mutating func forgetControllerIfEmpty() {
        guard present.isEmpty, let last = lastKnownDockLocationID else { return }
        if !others.values.contains(where: { DockMembership.isOnDock(usbLocationID: $0, dockLocationID: last) }) {
            lastKnownDockLocationID = nil
        }
    }
}
