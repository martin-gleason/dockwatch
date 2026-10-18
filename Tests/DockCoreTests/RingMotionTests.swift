// Created: 2026-10-18 17:03 -05:00 · Edited: 2026-10-18 17:27 -05:00
import XCTest
@testable import DockCore

/// D16, D20 — still by default, slow while held, one turn on connect or disconnect, home at rest.
final class RingMotionTests: XCTestCase {
    /// D20, M13: with nothing happening the ring does not move and asks for no frames.
    func testStillByDefault() {
        var m = RingMotion()
        XCTAssertFalse(m.isMoving)
        XCTAssertEqual(m.tick(), 0)
        XCTAssertEqual(m.phase, 0)
    }

    /// D20: while held the ring turns, slowly, at the low frame rate: one turn in `heldTurnSeconds`.
    func testHeldTurnsSlowlyAtTheLowRate() {
        var m = RingMotion(heldFramesPerSecond: 1, heldTurnSeconds: 60)
        m.setHeld(true)
        XCTAssertTrue(m.isMoving)
        XCTAssertEqual(m.currentFramesPerSecond, 1)
        for _ in 0..<60 { m.tick() }   // 60 s of frames at 1 fps
        XCTAssertEqual(m.phase, 0, accuracy: 1e-9, "exactly one turn, back where it started")
    }

    /// D20: a connect or disconnect is one full turn at the high rate, then stillness at home.
    func testDockChangeIsOneTurnThenStill() {
        var m = RingMotion(eventFramesPerSecond: 10, eventTurnSeconds: 1)
        m.dockChanged()
        XCTAssertTrue(m.isMoving)
        XCTAssertEqual(m.currentFramesPerSecond, 10)
        for _ in 0..<10 { m.tick() }
        XCTAssertEqual(m.phase, 0)
        XCTAssertFalse(m.isMoving)
        XCTAssertEqual(m.tick(), 0, "no drift after the turn")
    }

    /// D20: the flourish pauses the slow turn, lands at home, and the slow turn resumes.
    func testTurnWhileHeldThenSlowAgain() {
        var m = RingMotion(eventFramesPerSecond: 10, heldFramesPerSecond: 1, heldTurnSeconds: 60, eventTurnSeconds: 1)
        m.setHeld(true)
        m.dockChanged()
        for _ in 0..<10 { m.tick() }
        XCTAssertEqual(m.phase, 0)
        XCTAssertTrue(m.isMoving, "still held")
        XCTAssertEqual(m.currentFramesPerSecond, 1)
        m.tick()
        XCTAssertEqual(m.phase, 1.0 / 60, accuracy: 1e-9)
    }

    /// F7 review, finding 5: releasing the hold turns the ring home instead of leaving it anywhere.
    func testReleasingTheHoldReturnsHome() {
        var m = RingMotion(eventFramesPerSecond: 10, heldFramesPerSecond: 1, heldTurnSeconds: 60, eventTurnSeconds: 1)
        m.setHeld(true)
        for _ in 0..<15 { m.tick() }          // a quarter turn
        XCTAssertEqual(m.phase, 0.25, accuracy: 1e-9)
        m.setHeld(false)
        XCTAssertTrue(m.isMoving, "finishing the turn home")
        for _ in 0..<10 { m.tick() }
        XCTAssertEqual(m.phase, 0)
        XCTAssertFalse(m.isMoving)
    }

    /// F7 review, finding 5: a flourish started mid-turn still ends at home.
    func testFlourishFromMidTurnLandsAtHome() {
        var m = RingMotion(eventFramesPerSecond: 10, heldFramesPerSecond: 1, heldTurnSeconds: 60, eventTurnSeconds: 1)
        m.setHeld(true)
        for _ in 0..<30 { m.tick() }          // half a turn
        m.dockChanged()
        var frames = 0
        while m.turnRemaining > 0 { m.tick(); frames += 1 }
        XCTAssertEqual(m.phase, 0)
        XCTAssertEqual(frames, 15, "one and a half turns at ten frames a turn")
    }
}
