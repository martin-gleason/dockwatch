// Created: 2026-10-18 17:03 -05:00 · Edited: 2026-10-18 17:03 -05:00
import XCTest
@testable import DockCore

/// D16, D20 — still by default, slow while held, one turn on connect or disconnect.
final class RingMotionTests: XCTestCase {
    /// D20, M13: with nothing happening the ring does not move and asks for no frames.
    func testStillByDefault() {
        var m = RingMotion()
        XCTAssertFalse(m.isMoving)
        XCTAssertEqual(m.tick(), 0)
        XCTAssertEqual(m.phase, 0)
    }

    /// D20: while held the ring turns, slowly: one turn in `heldTurnSeconds`.
    func testHeldTurnsSlowly() {
        var m = RingMotion(framesPerSecond: 10, heldTurnSeconds: 60)
        m.setHeld(true)
        XCTAssertTrue(m.isMoving)
        for _ in 0..<600 { m.tick() }   // 60 s of frames
        XCTAssertEqual(m.phase, 0, accuracy: 1e-9, "exactly one turn, back where it started")
        m.setHeld(false)
        XCTAssertFalse(m.isMoving)
    }

    /// D20: a connect or disconnect is one full turn and then stillness.
    func testDockChangeIsOneTurnThenStill() {
        var m = RingMotion(framesPerSecond: 10, eventTurnSeconds: 1)
        m.dockChanged()
        XCTAssertTrue(m.isMoving)
        for _ in 0..<10 { m.tick() }
        XCTAssertEqual(m.phase, 0, accuracy: 1e-9)
        XCTAssertFalse(m.isMoving)
        XCTAssertEqual(m.tick(), 0, "no drift after the turn")
    }

    /// D20: the flourish runs at its own speed even while held, then the slow turn resumes.
    func testTurnWhileHeldThenSlowAgain() {
        var m = RingMotion(framesPerSecond: 10, heldTurnSeconds: 60, eventTurnSeconds: 1)
        m.setHeld(true)
        m.dockChanged()
        for _ in 0..<10 { m.tick() }
        XCTAssertEqual(m.phase, 0, accuracy: 1e-9)
        XCTAssertTrue(m.isMoving, "still held")
        m.tick()
        XCTAssertEqual(m.phase, 1.0 / 600, accuracy: 1e-9)
    }
}
