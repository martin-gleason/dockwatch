// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 12:15 -05:00
import XCTest
@testable import DockCore

/// FR3, NFR6 — the log is JSON Lines, append-only, rotated once, and never throws into the UI.
final class EventStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("dockwatch-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func lines(_ url: URL) throws -> [String] {
        try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init)
    }

    /// FR3, M3: three appends are three lines, in order, each decoding to what was written.
    /// Opening with truncate instead of append (M3) leaves one line.
    func testAppendPreservesPriorLines() throws {
        let store = EventStore(directory: dir)
        let events = [
            Event(kind: .usbAttached, subject: "Thunderbolt 4 Dock", detail: ["vendor": "0x1532"]),
            Event(kind: .volumeMounted, subject: "Down Under", detail: ["bsd": "disk5s1"]),
            Event(kind: .systemSleep, subject: "system"),
        ]
        for e in events { XCTAssertTrue(store.append(e)) }
        let got = try lines(store.url).map(EventLine.decode)
        XCTAssertEqual(got.count, 3)
        XCTAssertEqual(got.map(\.kind), events.map(\.kind))
        XCTAssertEqual(got.map(\.subject), events.map(\.subject))
        XCTAssertEqual(got[0].detail["vendor"], "0x1532")
        XCTAssertEqual(store.count, 3)
        XCTAssertNil(store.lastError)
    }

    /// NFR6: at the threshold the file moves to `.1.jsonl`; a second rotation replaces it,
    /// so exactly one previous file ever exists.
    func testRotationKeepsExactlyOnePreviousFile() throws {
        let store = EventStore(directory: dir, maxBytes: 300)
        let one = try EventLine.encode(Event(kind: .systemWake, subject: "system")).utf8.count + 1
        let perFile = 300 / one        // lines that fit before the threshold trips
        for _ in 0..<(perFile + 1) { store.append(Event(kind: .systemWake, subject: "system")) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.rotatedURL.path), "first rotation")
        XCTAssertEqual(try lines(store.rotatedURL).count, perFile)
        XCTAssertEqual(try lines(store.url).count, 1)

        for _ in 0..<(perFile + 1) { store.append(Event(kind: .systemSleep, subject: "system")) }
        // The second rotation fires when the surviving wake line plus the new sleep lines no
        // longer fit, so the replaced previous file holds exactly `perFile` lines, beginning
        // with that wake line: the middle of the stream, not the start of it.
        let previous = try lines(store.rotatedURL).map(EventLine.decode)
        XCTAssertEqual(previous.count, perFile, "the replaced previous file holds the middle batch")
        XCTAssertEqual(previous.first?.kind, .systemWake)
        XCTAssertEqual(previous.last?.kind, .systemSleep)
        XCTAssertEqual(try lines(store.url).count, 2)
        let all = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".jsonl") }.sorted()
        XCTAssertEqual(all, ["events.1.jsonl", "events.jsonl"])
    }

    /// NFR6: an unwritable location is reported, not thrown.
    func testUnwritableDirectorySetsLastErrorWithoutThrowing() {
        let store = EventStore(directory: URL(fileURLWithPath: "/dev/null/dockwatch"))
        XCTAssertFalse(store.append(Event(kind: .systemWake, subject: "system")))
        XCTAssertNotNil(store.lastError)
        XCTAssertEqual(store.count, 0)
    }

    /// FR3: one JSON object per line, keys sorted, timestamp in ISO 8601 with fractions.
    func testLineShape() throws {
        let ts = Date(timeIntervalSince1970: 1_760_000_000.25)
        let line = try EventLine.encode(Event(ts: ts, kind: .powerDisconnected, subject: "Battery Power", detail: ["lastWatts": "90"]))
        XCTAssertEqual(line, #"{"detail":{"lastWatts":"90"},"kind":"power.disconnected","subject":"Battery Power","ts":"2025-10-09T08:53:20.250Z"}"#)
        XCTAssertEqual(try EventLine.decode(line).ts, ts)
    }

    /// FR3: every kind the spec names has a stable wire name.
    func testKindsAreTheSpecsNames() {
        XCTAssertEqual(Event.Kind.allCases.map(\.rawValue), [
            "usb.attached", "usb.detached",
            "volume.mounted", "volume.unmounted", "volume.disappeared",
            "system.sleep", "system.wake",   // no darkwake: not observable through public API (D18)
            "power.connected", "power.disconnected",
        ])
    }
}
