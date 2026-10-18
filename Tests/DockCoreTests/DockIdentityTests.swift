// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 11:40 -05:00
import XCTest
@testable import DockCore

/// FR2 — the dock is recognised by vendor and product ID. D4 names the IDs.
final class DockIdentityTests: XCTestCase {
    private func device(_ vendor: Int, _ product: Int, _ name: String) -> USBDeviceDescriptor {
        USBDeviceDescriptor(vendorID: vendor, productID: product, productName: name, locationID: 0x0214_8000, registryID: 42)
    }

    /// FR2: the real dock, as this Mac enumerates it.
    func testDefaultIdentityMatchesTheDock() {
        XCTAssertTrue(DockIdentity.razerThunderbolt4Dock.matches(device(0x1532, 0x122E, "Thunderbolt 4 Dock")))
    }

    /// FR2, M4: the Chroma lighting controller shares the dock's vendor ID and is not the dock.
    func testChromaControllerIsNotTheDock() {
        XCTAssertFalse(DockIdentity.razerThunderbolt4Dock.matches(device(0x1532, 0x0F21, "RAZER THUNDERBOLT 4 DOCK CHROMA")))
    }

    /// FR2, M4: same vendor, different product. Vendor-only matching would call a Razer
    /// mouse a dock; this is the test M4 must turn red.
    func testRazerMouseIsNotTheDock() {
        XCTAssertFalse(DockIdentity.razerThunderbolt4Dock.matches(device(0x1532, 0x0084, "Razer DeathAdder")))
    }

    /// FR2: a custom identity works the same way (groundwork for the v1.1 picker, not a feature).
    func testCustomIdentityMatchesOnlyItself() {
        let id = DockIdentity(vendorID: 0x2188, productID: 0x0001)
        XCTAssertTrue(id.matches(device(0x2188, 0x0001, "TS4")))
        XCTAssertFalse(id.matches(device(0x1532, 0x122E, "Thunderbolt 4 Dock")))
    }
}
