// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 13:04 -05:00
import XCTest
@testable import DockCore

/// FR1, FR2 — USB events fold into docked / undocked, and only transitions report a change.
final class DockTrackerTests: XCTestCase {
    private let dock = USBDeviceDescriptor(vendorID: 0x1532, productID: 0x122E, productName: "Thunderbolt 4 Dock", locationID: 0x0214_8000, registryID: 100)
    private let dock2 = USBDeviceDescriptor(vendorID: 0x1532, productID: 0x122E, productName: "Thunderbolt 4 Dock", locationID: 0x0114_8000, registryID: 200)
    private let keyboard = USBDeviceDescriptor(vendorID: 0x24F0, productID: 0x0141, productName: "Das Keyboard", locationID: 0x0214_3240, registryID: 300)

    /// FR1: before any event the icon must say "not connected", not "unknown".
    func testStartsUndocked() {
        XCTAssertEqual(DockTracker().state, .undocked)
    }

    /// FR2: the dock attaching is the transition to docked.
    func testDockAttachMakesDocked() {
        var t = DockTracker()
        XCTAssertTrue(t.apply(USBEvent(kind: .attached, device: dock)))
        XCTAssertEqual(t.state, .docked)
    }

    /// FR2: the dock detaching is the transition to undocked.
    func testDockDetachMakesUndocked() {
        var t = DockTracker()
        t.apply(USBEvent(kind: .attached, device: dock))
        XCTAssertTrue(t.apply(USBEvent(kind: .detached, device: dock)))
        XCTAssertEqual(t.state, .undocked)
    }

    /// FR2: other devices on the dock never move the dock state.
    func testUnrelatedDeviceDoesNotChangeState() {
        var t = DockTracker()
        XCTAssertFalse(t.apply(USBEvent(kind: .attached, device: keyboard)))
        XCTAssertEqual(t.state, .undocked)
        t.apply(USBEvent(kind: .attached, device: dock))
        XCTAssertFalse(t.apply(USBEvent(kind: .detached, device: keyboard)))
        XCTAssertEqual(t.state, .docked)
    }

    /// FR2: a replug can enumerate the new entry before the old one terminates; the
    /// tracker must not flash "undocked" in between.
    func testTwoMatchingEntriesStayDockedUntilBothLeave() {
        var t = DockTracker()
        t.apply(USBEvent(kind: .attached, device: dock))
        XCTAssertFalse(t.apply(USBEvent(kind: .attached, device: dock2)))
        XCTAssertFalse(t.apply(USBEvent(kind: .detached, device: dock)))
        XCTAssertEqual(t.state, .docked)
        XCTAssertTrue(t.apply(USBEvent(kind: .detached, device: dock2)))
        XCTAssertEqual(t.state, .undocked)
    }

    /// FR9: the dock's USB location is known while docked and not otherwise.
    func testDockLocationFollowsPresence() {
        var t = DockTracker()
        XCTAssertNil(t.dockLocationID)
        t.apply(USBEvent(kind: .attached, device: dock))
        XCTAssertEqual(t.dockLocationID, 0x0214_8000)
        t.apply(USBEvent(kind: .detached, device: dock))
        XCTAssertNil(t.dockLocationID)
    }

    /// FR1: a duplicate attach or a detach of something never seen is not a transition,
    /// so the icon is not redrawn for nothing.
    func testApplyReportsChangeOnlyOnTransition() {
        var t = DockTracker()
        XCTAssertFalse(t.apply(USBEvent(kind: .detached, device: dock)))
        XCTAssertTrue(t.apply(USBEvent(kind: .attached, device: dock)))
        XCTAssertFalse(t.apply(USBEvent(kind: .attached, device: dock)))
    }
}
