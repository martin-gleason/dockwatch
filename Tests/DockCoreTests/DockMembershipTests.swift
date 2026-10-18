// Created: 2026-10-18 13:04 -05:00 · Edited: 2026-10-18 13:04 -05:00
import XCTest
@testable import DockCore

/// FR9 — which disks count as "on the dock". Locations are this Mac's real ones.
final class DockMembershipTests: XCTestCase {
    private let dock: UInt32 = 0x0214_8000   // "Thunderbolt 4 Dock", USB 2 chain

    /// FR9, M7: the JMicron enclosure hangs off the dock's USB 3 hub, a sibling of the dock
    /// device itself, so a whole-location comparison would wrongly exclude it.
    func testSiblingHubIsOnTheDock() {
        XCTAssertTrue(DockMembership.isOnDock(usbLocationID: 0x0224_2000, dockLocationID: dock))
        XCTAssertTrue(DockMembership.isOnDock(usbLocationID: 0x0223_0000, dockLocationID: dock))
    }

    /// FR9: the Mac's own ports are other controllers.
    func testBuiltInPortsAreNotOnTheDock() {
        XCTAssertFalse(DockMembership.isOnDock(usbLocationID: 0x0110_0000, dockLocationID: dock))
        XCTAssertFalse(DockMembership.isOnDock(usbLocationID: 0x0010_0000, dockLocationID: dock))
    }

    /// FR9: the rule is symmetric in the controller byte alone.
    func testDockItselfIsOnTheDock() {
        XCTAssertTrue(DockMembership.isOnDock(usbLocationID: dock, dockLocationID: dock))
    }
}
