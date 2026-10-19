// Created: 2026-10-18 16:54 -05:00 · Edited: 2026-10-18 20:05 -05:00
// F4-T3 — one notification for a dock pull, one per lone drop (FR6, D22, D27). Pure.
import Foundation

public struct LossCoalescer: Equatable {
    public enum Loss: Equatable {
        case device(String)
        case volume(String)
    }

    public enum Flush: Equatable {
        /// The dock device itself went away inside the window: say it once.
        case dockDisconnected(devices: Int, volumes: Int)
        /// Things dropped while the dock stayed: each one is news.
        case lone([Loss])
    }

    public let window: TimeInterval
    public private(set) var pending: [Loss] = []
    public private(set) var openedAt: Date?
    private var dockWentAway = false

    public init(window: TimeInterval = 2) {
        self.window = window
    }

    /// Adds a loss. Returns true when this loss opened a window, which is the caller's cue
    /// to arrange one flush `window` seconds from now.
    @discardableResult
    public mutating func add(_ loss: Loss, at now: Date = Date()) -> Bool {
        // The name goes into a notification body; it is plain text from here (C3 review, 2).
        switch loss {
        case .device(let n): pending.append(.device(Event.plain(n)))
        case .volume(let n): pending.append(.volume(Event.plain(n)))
        }
        if openedAt == nil {
            openedAt = now
            return true
        }
        return false
    }

    /// The dock device itself detached (the tracker went undocked). Returns true when this
    /// opened the window, the caller's cue to arrange the one flush (same contract as `add`).
    @discardableResult
    public mutating func dockDetached(at now: Date = Date()) -> Bool {
        dockWentAway = true
        if openedAt == nil {
            openedAt = now
            return true
        }
        return false
    }

    /// Nil when nothing was collected.
    public mutating func flush() -> Flush? {
        defer { pending = []; openedAt = nil; dockWentAway = false }
        if pending.isEmpty && !dockWentAway { return nil }
        let devices = pending.filter { if case .device = $0 { return true } else { return false } }.count
        let volumes = pending.count - devices
        let flush: Flush = dockWentAway ? .dockDisconnected(devices: devices, volumes: volumes) : .lone(pending)
        return flush
    }
}

public extension LossCoalescer.Flush {
    var title: String {
        switch self {
        case .dockDisconnected: return "Dock disconnected"
        case .lone(let losses): return losses.count == 1 ? "Dropped from the dock" : "\(losses.count) dropped from the dock"
        }
    }

    var body: String {
        switch self {
        case .dockDisconnected(let d, let v):
            return "\(d) device\(d == 1 ? "" : "s") and \(v) volume\(v == 1 ? "" : "s") went with it."
        case .lone(let losses):
            return losses.map {
                switch $0 {
                case .device(let n): return n
                case .volume(let n): return "\(n) (volume, not ejected)"
                }
            }.joined(separator: ", ")
        }
    }
}
