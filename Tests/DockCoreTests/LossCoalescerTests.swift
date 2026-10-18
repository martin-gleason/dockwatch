// Created: 2026-10-18 16:54 -05:00 · Edited: 2026-10-18 16:54 -05:00
import XCTest
@testable import DockCore

/// FR6, D22, D27 — one notification for a dock pull, one per lone drop.
final class LossCoalescerTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_760_000_000)

    /// FR6: a lone drop is its own news.
    func testLoneDropFlushesAsItself() {
        var c = LossCoalescer()
        XCTAssertTrue(c.add(.device("Das Keyboard"), at: t0), "first loss opens the window")
        XCTAssertEqual(c.flush(), .lone([.device("Das Keyboard")]))
        XCTAssertNil(c.flush(), "nothing left")
    }

    /// FR6, D22, M12: the dock itself going away inside the window turns seventeen losses into one line.
    func testDockPullIsOneSummary() {
        var c = LossCoalescer()
        c.add(.volume("Backups"), at: t0)
        for n in ["Das Keyboard", "USB Receiver", "USB 10/100/1000 LAN"] { c.add(.device(n), at: t0.addingTimeInterval(0.3)) }
        c.dockDetached(at: t0.addingTimeInterval(0.5))
        XCTAssertEqual(c.flush(), .dockDisconnected(devices: 3, volumes: 1))
    }

    /// FR6: a second loss inside an open window does not open another.
    func testSecondLossDoesNotReopenTheWindow() {
        var c = LossCoalescer()
        XCTAssertTrue(c.add(.device("a"), at: t0))
        XCTAssertFalse(c.add(.device("b"), at: t0.addingTimeInterval(1)))
        XCTAssertEqual(c.flush(), .lone([.device("a"), .device("b")]))
    }

    /// FR6: the words the notification carries.
    func testTitlesAndBodies() {
        XCTAssertEqual(LossCoalescer.Flush.dockDisconnected(devices: 17, volumes: 4).title, "Dock disconnected")
        XCTAssertEqual(LossCoalescer.Flush.dockDisconnected(devices: 1, volumes: 1).body, "1 device and 1 volume went with it.")
        XCTAssertEqual(LossCoalescer.Flush.lone([.volume("Down Under")]).title, "Dropped from the dock")
        XCTAssertEqual(LossCoalescer.Flush.lone([.volume("Down Under")]).body, "Down Under (volume, not ejected)")
        XCTAssertEqual(LossCoalescer.Flush.lone([.device("a"), .device("b")]).title, "2 dropped from the dock")
    }
}
