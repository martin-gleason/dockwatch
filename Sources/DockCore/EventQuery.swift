// Created: 2026-10-18 16:54 -05:00 · Edited: 2026-10-18 17:10 -05:00
// F4-T1 — the recent events and the 24-hour counters the menu shows (FR4, D28). Pure.
import Foundation

public struct Counters: Equatable {
    public var devicesLost = 0
    public var volumesLost = 0
    public var chargerDrops = 0
    public var wakes = 0
    public init(devicesLost: Int = 0, volumesLost: Int = 0, chargerDrops: Int = 0, wakes: Int = 0) {
        self.devicesLost = devicesLost; self.volumesLost = volumesLost; self.chargerDrops = chargerDrops; self.wakes = wakes
    }
}

/// A bounded ring of the most recent events, seeded from the log's tail at launch and fed
/// by every event recorded since.
public struct EventQuery: Equatable {
    public let capacity: Int
    public private(set) var events: [Event] = []

    public init(capacity: Int = 500, seed: [Event] = []) {
        self.capacity = capacity
        for e in seed { append(e) }
    }

    public mutating func append(_ event: Event) {
        events.append(event)
        if events.count > capacity { events.removeFirst(events.count - capacity) }
    }

    /// Newest first.
    public func recent(_ n: Int) -> [Event] {
        Array(events.suffix(n).reversed())
    }

    /// D28: devices lost = USB detaches on the dock; volumes lost = unclean disappearances on
    /// the dock; charger drops = disconnects that were not the launch baseline; wakes = full
    /// wakes (dark wakes are not observable, D18). The window is by event time, not position (M5).
    public func counters(window: TimeInterval = 24 * 3600, now: Date = Date()) -> Counters {
        let cutoff = now.addingTimeInterval(-window)
        var c = Counters()
        for e in events where e.ts >= cutoff {
            switch e.kind {
            case .usbDetached where e.detail["dock"] == "true": c.devicesLost += 1
            case .volumeDisappeared where e.detail["dock"] == "true": c.volumesLost += 1
            case .powerDisconnected where e.detail["initial"] != "true": c.chargerDrops += 1
            case .systemWake: c.wakes += 1
            default: break
            }
        }
        return c
    }
}

public extension Event {
    /// One formatter for the process (the reviews keep measuring the per-call one at 50 µs).
    static let menuTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// One menu line: `14:02:17  usb.detached  Das Keyboard`.
    var menuLine: String {
        let f = Self.menuTime
        var extra = ""
        if detail["initial"] == "true" { extra = "  at launch" }
        else if let r = detail["result"] { extra = "  (\(r))" }
        else if kind == .powerConnected, let w = detail["watts"] { extra = "  \(w) W" }
        else if kind == .powerDisconnected, let w = detail["lastWatts"] { extra = "  was \(w) W" }
        return "\(f.string(from: ts))  \(kind.rawValue)  \(subject)\(extra)"
    }
}
