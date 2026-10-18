// Created: 2026-10-18 17:10 -05:00 · Edited: 2026-10-18 17:10 -05:00
import XCTest
@testable import DockCore

/// D28, FR4, FR6 — "on the dock" must hold for every device of a dock pull, whatever order
/// IOKit terminates them in. The fixture is the one recorded pull (events.jsonl,
/// 2026-10-18T17:30:29Z, 18 lines): the dock's own device is eleventh, and the seven after
/// it were neither counted nor collected before F4b (F4 review, finding 1).
final class DockPullFixtureTests: XCTestCase {
    static let pull: [(vendor: Int, product: Int, location: UInt32, name: String)] = [
        (0x8087, 0x0b40, 0x02200000, "USB3.0 Hub"),
        (0x2109, 0x0711, 0x02230000, "USB3.0 SATA Bridge"),
        (0x05e3, 0x0626, 0x02243000, "USB3.1 Hub"),
        (0x152d, 0x0567, 0x02242000, "External USB 3.0"),
        (0x2109, 0x0812, 0x02243200, "USB3.0 Hub"),
        (0x0bda, 0x8153, 0x02245000, "USB 10_100_1000 LAN"),
        (0x1532, 0x0f30, 0x02240000, "USB3.0 Hub"),
        (0x1d5c, 0x5801, 0x02100000, "USB2.0 Hub"),
        (0x1532, 0x0f2f, 0x02140000, "USB2.0 Hub"),
        (0x0bda, 0x5408, 0x02110000, "USB2.1 Hub"),
        (0x1532, 0x122e, 0x02148000, "Thunderbolt 4 Dock"),
        (0x05ac, 0x0503, 0x02120000, "Apple Watch Magnetic Charging Cable"),
        (0x1532, 0x0f21, 0x02146000, "RAZER THUNDERBOLT 4 DOCK CHROMA"),
        (0x05e3, 0x0610, 0x02143000, "USB2.1 Hub"),
        (0x2109, 0x2812, 0x02143200, "USB2.0 Hub"),
        (0x239a, 0x8029, 0x02111000, "T1000_E_BOOT"),
        (0x24f0, 0x0141, 0x02143240, "Das Keyboard"),
        (0x046d, 0xc52b, 0x02143210, "USB Receiver"),
    ]

    private func devices() -> [USBDeviceDescriptor] {
        Self.pull.enumerated().map { i, d in
            USBDeviceDescriptor(vendorID: d.vendor, productID: d.product, productName: d.name, locationID: d.location, registryID: UInt64(1000 + i))
        }
    }

    /// Attach everything (as the priming pass does), then detach in the given order, judging
    /// membership before each detach is applied, as the app does.
    private func judgeDetaches(order: [USBDeviceDescriptor]) -> (onDock: Int, flush: LossCoalescer.Flush?) {
        var tracker = DockTracker()
        var losses = LossCoalescer()
        for d in devices() { tracker.apply(USBEvent(kind: .attached, device: d)) }
        XCTAssertEqual(tracker.state, .docked)
        var onDock = 0
        for d in order {
            let member = tracker.isOnDock(d)
            if member { onDock += 1 }
            let changed = tracker.apply(USBEvent(kind: .detached, device: d))
            if changed, tracker.state == .undocked {
                losses.dockDetached()
            } else if member, !tracker.identity.matches(d) {
                losses.add(.device(d.productName ?? "?"))
            }
        }
        return (onDock, losses.flush())
    }

    /// FR4, FR6, M14: the recorded order — seven children terminate after the dock device.
    func testRecordedPullCountsEveryChild() {
        let r = judgeDetaches(order: devices())
        XCTAssertEqual(r.onDock, 18, "all eighteen lines are the dock's")
        XCTAssertEqual(r.flush, .dockDisconnected(devices: 17, volumes: 0))
    }

    /// FR4, FR6: the dock device first, an order IOKit is free to deliver.
    func testDockFirstOrderCountsEveryChild() {
        var order = devices()
        let dock = order.remove(at: 10)
        order.insert(dock, at: 0)
        let r = judgeDetaches(order: order)
        XCTAssertEqual(r.onDock, 18)
        XCTAssertEqual(r.flush, .dockDisconnected(devices: 17, volumes: 0))
    }

    /// FR4: after the dock is gone, a device on another controller is still not the dock's.
    func testOtherControllerIsNeverTheDocks() {
        var tracker = DockTracker()
        for d in devices() { tracker.apply(USBEvent(kind: .attached, device: d)) }
        for d in devices() { tracker.apply(USBEvent(kind: .detached, device: d)) }
        let iphone = USBDeviceDescriptor(vendorID: 0x05ac, productID: 0x12a8, productName: "iPhone", locationID: 0x01100000, registryID: 5)
        XCTAssertFalse(tracker.isOnDock(iphone))
        let straggler = USBDeviceDescriptor(vendorID: 0x046d, productID: 0xc52b, productName: "USB Receiver", locationID: 0x02143210, registryID: 6)
        XCTAssertTrue(tracker.isOnDock(straggler), "the dock's controller is remembered")
    }

    /// FR4: before any dock was ever seen, nothing is the dock's except the dock itself.
    func testNothingIsOnTheDockBeforeItWasSeen() {
        let tracker = DockTracker()
        XCTAssertFalse(tracker.isOnDock(devices()[0]))
        XCTAssertTrue(tracker.isOnDock(devices()[10]), "the identifying device is always the dock")
    }
}
