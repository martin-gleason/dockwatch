// Created: 2026-10-18 16:54 -05:00 · Edited: 2026-10-18 17:10 -05:00
import XCTest
@testable import DockCore

/// FR4, D28 — the recent list and the 24-hour counters.
final class EventQueryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_760_000_000)
    private func at(_ secondsAgo: TimeInterval, _ kind: Event.Kind, _ subject: String = "x", _ detail: [String: String] = [:]) -> Event {
        Event(ts: now.addingTimeInterval(-secondsAgo), kind: kind, subject: subject, detail: detail)
    }

    /// FR4: newest first, bounded by n.
    func testRecentIsNewestFirst() {
        var q = EventQuery()
        q.append(at(30, .usbAttached, "a")); q.append(at(20, .usbAttached, "b")); q.append(at(10, .usbAttached, "c"))
        XCTAssertEqual(q.recent(2).map(\.subject), ["c", "b"])
    }

    /// FR4: the ring forgets the oldest beyond its capacity.
    func testCapacityIsBounded() {
        var q = EventQuery(capacity: 3)
        for i in 0..<5 { q.append(at(TimeInterval(50 - i), .systemWake, "\(i)")) }
        XCTAssertEqual(q.events.map(\.subject), ["2", "3", "4"])
    }

    /// FR4, M5: events older than the window do not count, whatever their position in the ring.
    func testWindowExcludesOldEvents() {
        var q = EventQuery()
        q.append(at(25 * 3600, .systemWake))           // outside
        q.append(at(23 * 3600, .systemWake))           // inside
        q.append(at(2 * 3600, .usbDetached, "kbd", ["dock": "true"]))
        XCTAssertEqual(q.counters(now: now), Counters(devicesLost: 1, volumesLost: 0, chargerDrops: 0, wakes: 1))
    }

    /// D28: only dock devices and volumes count; the launch baseline power line does not.
    func testCountersFollowTheDefinitions() {
        var q = EventQuery()
        q.append(at(100, .usbDetached, "iPhone"))                                  // not on the dock
        q.append(at(90, .usbDetached, "Das Keyboard", ["dock": "true"]))
        q.append(at(80, .volumeDisappeared, "Down Under", ["dock": "true"]))
        q.append(at(70, .volumeUnmounted, "Down Under", ["dock": "true"]))        // clean: not a loss
        q.append(at(60, .powerDisconnected, "Battery Power", ["initial": "true"])) // baseline
        q.append(at(50, .powerDisconnected, "Battery Power", ["lastWatts": "90"]))
        q.append(at(40, .systemWake, "system"))
        XCTAssertEqual(q.counters(now: now), Counters(devicesLost: 1, volumesLost: 1, chargerDrops: 1, wakes: 1))
    }

    /// FR4: one readable line per event; a launch baseline says so, so the list agrees with the counters.
    func testMenuLine() {
        let e = Event(ts: now, kind: .powerDisconnected, subject: "Battery Power", detail: ["lastWatts": "90"])
        XCTAssertTrue(e.menuLine.hasSuffix("power.disconnected  Battery Power  was 90 W"), e.menuLine)
        let b = Event(ts: now, kind: .powerDisconnected, subject: "Battery Power", detail: ["initial": "true"])
        XCTAssertTrue(b.menuLine.hasSuffix("power.disconnected  Battery Power  at launch"), b.menuLine)
    }
}
