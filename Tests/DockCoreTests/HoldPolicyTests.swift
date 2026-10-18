// Created: 2026-10-18 12:40 -05:00 · Edited: 2026-10-18 12:40 -05:00
import XCTest
@testable import DockCore

/// FR5 — hold exactly when the toggle is on and the dock is present; re-apply on wake.
final class HoldPolicyTests: XCTestCase {
    /// FR5, M1: the dock leaving releases the hold within the same decision.
    func testUndockReleasesHold() {
        var p = HoldPolicy(toggle: true, docked: true)
        XCTAssertTrue(p.shouldHold)
        let d = p.apply(.dockChanged(false))
        XCTAssertFalse(d.hold)
        XCTAssertFalse(p.shouldHold)
    }

    /// FR5, M2: with the toggle off nothing holds, whatever the dock does.
    func testToggleOffNeverHolds() {
        var p = HoldPolicy(toggle: false, docked: true)
        XCTAssertFalse(p.shouldHold)
        XCTAssertFalse(p.apply(.dockChanged(true)).hold)
        XCTAssertFalse(p.apply(.didWake).hold)
        XCTAssertFalse(p.apply(.dockChanged(false)).hold)
    }

    /// FR5, NFR8, M6: a wake while docked and on asks for the assertion to be re-created.
    func testWakeWhileDockedReasserts() {
        var p = HoldPolicy(toggle: true, docked: true)
        let d = p.apply(.didWake)
        XCTAssertTrue(d.hold)
        XCTAssertTrue(d.reapply)
    }

    /// FR5: a wake while not docked asks for release, and does not invent a hold.
    func testWakeWhileUndockedDoesNotHold() {
        var p = HoldPolicy(toggle: true, docked: false)
        XCTAssertFalse(p.apply(.didWake).hold)
    }

    /// FR5, D10: the default is off and undocked; turning the toggle on with no dock does nothing yet,
    /// and the dock arriving then holds.
    func testToggleOnThenDockArrivalHolds() {
        var p = HoldPolicy()
        XCTAssertFalse(p.shouldHold)
        XCTAssertFalse(p.apply(.toggleChanged(true)).hold)
        let d = p.apply(.dockChanged(true))
        XCTAssertTrue(d.hold)
        XCTAssertFalse(d.reapply)
    }

    /// FR5: the RR14 policy — a flicker of the identifying device is followed exactly, no grace.
    func testFlickerReleasesThenReasserts() {
        var p = HoldPolicy(toggle: true, docked: true)
        XCTAssertFalse(p.apply(.dockChanged(false)).hold)
        XCTAssertTrue(p.apply(.dockChanged(true)).hold)
    }
}
