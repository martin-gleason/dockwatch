// Created: 2026-10-18 13:55 -05:00 · Edited: 2026-10-18 19:25 -05:00
import XCTest
@testable import DockCore

/// FR9 — the result of an eject is reported where the owner looks: the menu.
final class EjectMenuModelTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_760_000_000)
    private let down = (bsdName: "disk5s2", title: "Down Under")
    private let backups = (bsdName: "disk10s2", title: "Backups")

    /// FR9, M10: after a successful eject the volume is gone from the mounted list, and its
    /// "Ejected" row must still be there to read.
    func testSuccessfulEjectStaysVisibleAfterUnmount() {
        var m = EjectMenuModel()
        m.record(bsdName: down.bsdName, title: down.title, text: "Ejected", at: t0)
        let rows = m.rows(mounted: [backups], now: t0.addingTimeInterval(3))
        XCTAssertEqual(rows.map(\.title), ["Backups", "Down Under"])
        guard rows.count == 2 else { return XCTFail("the ejected volume's row is missing") }
        XCTAssertEqual(rows[1].status, "Ejected")
        XCTAssertFalse(rows[1].isEjectable)
        XCTAssertTrue(rows[0].isEjectable)
    }

    /// FR9, M11: a volume that mounts again (replug, diskutil) must not say "Ejected".
    func testRemountClearsResult() {
        var m = EjectMenuModel()
        m.record(bsdName: down.bsdName, title: down.title, text: "Ejected", at: t0)
        m.volumeMounted(bsdName: down.bsdName)
        let rows = m.rows(mounted: [down], now: t0.addingTimeInterval(5))
        XCTAssertEqual(rows.count, 1)
        XCTAssertNil(rows[0].status)
        XCTAssertTrue(rows[0].isEjectable)
    }

    /// FR9: a blocked result sits beside the still-mounted volume.
    func testBlockedResultSitsBesideMountedVolume() {
        var m = EjectMenuModel()
        m.record(bsdName: backups.bsdName, title: backups.title, text: "In use by a system process", at: t0)
        let rows = m.rows(mounted: [backups, down], now: t0.addingTimeInterval(1))
        XCTAssertEqual(rows.map(\.status), ["In use by a system process", nil])
    }

    /// FR9: results expire after the lifetime and the reporting row goes with them.
    func testResultsExpire() {
        var m = EjectMenuModel(lifetime: 60)
        m.record(bsdName: down.bsdName, title: down.title, text: "Ejected", at: t0)
        XCTAssertEqual(m.rows(mounted: [], now: t0.addingTimeInterval(59)).count, 1)
        XCTAssertEqual(m.rows(mounted: [], now: t0.addingTimeInterval(61)).count, 0)
    }

    /// C3: a result that says the volume was unmounted never decorates a row that is mounted
    /// (security review 2026-10-18, finding 11); a refusal still does.
    func testDoneResultNeverShowsOnAMountedRow() {
        var m = EjectMenuModel()
        m.record(bsdName: down.bsdName, title: down.title, text: "Ejected", done: true, at: t0)
        m.record(bsdName: backups.bsdName, title: backups.title, text: "In use by a system process", done: false, at: t0)
        let rows = m.rows(mounted: [down, backups], now: t0.addingTimeInterval(1))
        XCTAssertEqual(rows.map(\.status), [nil, "In use by a system process"])
        XCTAssertEqual(rows.map(\.isEjectable), [true, true])
    }
}
