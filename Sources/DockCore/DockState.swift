// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 11:40 -05:00
// F1-T2 — folds USB events into "is the dock here" (FR1, FR2). Pure; no IOKit.

public enum DockState: String, Equatable {
    case docked, undocked
}

public struct DockTracker: Equatable {
    public let identity: DockIdentity
    /// Registry IDs of matching devices currently present. A set, not a flag, so two
    /// matching devices (or a replug that enumerates before the old entry terminates)
    /// cannot leave the tracker saying "undocked" while a dock is still attached.
    private var present: Set<UInt64> = []

    public init(identity: DockIdentity = .razerThunderbolt4Dock) {
        self.identity = identity
    }

    public var state: DockState { present.isEmpty ? .undocked : .docked }

    /// Applies one event. Returns `true` only when `state` changed.
    @discardableResult
    public mutating func apply(_ event: USBEvent) -> Bool {
        guard identity.matches(event.device) else { return false }
        let before = state
        switch event.kind {
        case .attached: present.insert(event.device.registryID)
        case .detached: present.remove(event.device.registryID)
        }
        return state != before
    }
}
