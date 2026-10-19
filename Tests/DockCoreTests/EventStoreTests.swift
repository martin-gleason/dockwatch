// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 19:25 -05:00
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

    /// FR4: the tail seeds the menu at launch; a line that does not decode is skipped (F2 review note).
    func testTailSkipsABadLine() throws {
        let store = EventStore(directory: dir)
        store.append(Event(kind: .systemWake, subject: "system"))
        let fd = FileHandle(forWritingAtPath: store.url.path)!
        try fd.seekToEnd(); fd.write(Data("{\"kind\":\"from.the.future\",\"subject\":\"?\",\"ts\":\"2030-01-01T00:00:00.000Z\"}\n".utf8)); try fd.close()
        store.append(Event(kind: .systemSleep, subject: "system"))
        XCTAssertEqual(store.tail(10).map(\.kind), [.systemWake, .systemSleep])
        XCTAssertEqual(store.tail(1).map(\.kind), [.systemSleep])
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
            "volume.eject",   // FR9
            "hold.on", "hold.off",   // D21
        ])
    }

    /// C3-T1, M15: a symlink planted at the log path is refused on write and on read; the
    /// link's target is never written through (security review 2026-10-18, finding 6).
    func testSymlinkAtLogPathIsRefusedNotFollowed() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let target = dir.appendingPathComponent("elsewhere.txt")
        try Data("untouched\n".utf8).write(to: target)
        let store = EventStore(directory: dir)
        try FileManager.default.createSymbolicLink(at: store.url, withDestinationURL: target)
        XCTAssertFalse(store.append(Event(kind: .systemWake, subject: "system")))
        XCTAssertNotNil(store.lastError)
        XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "untouched\n", "nothing went through the link")
        XCTAssertEqual(store.tail(10).count, 0, "nothing is read through it either")
    }

    /// C3-T1: a directory at the log path is reported, not written into.
    func testDirectoryAtLogPathIsReported() throws {
        let store = EventStore(directory: dir)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: true)
        XCTAssertFalse(store.append(Event(kind: .systemWake, subject: "system")))
        XCTAssertNotNil(store.lastError, "open refuses a directory (EISDIR) before the regular-file check can")
        XCTAssertEqual(store.tail(10).count, 0)
    }

    /// C3-T2, M16: one unterminated line larger than the read window, appended after real
    /// events, does not blank the seed: the window holds only that line, which is skipped
    /// as undecodable, and nothing real is dropped for being "probably torn".
    func testOversizedTrailingLineDoesNotBlankTheTail() throws {
        let store = EventStore(directory: dir)
        for _ in 0..<50 { store.append(Event(kind: .systemWake, subject: "system")) }
        let fd = FileHandle(forWritingAtPath: store.url.path)!
        try fd.seekToEnd(); fd.write(Data(String(repeating: "x", count: 600_000).utf8)); try fd.close()
        XCTAssertEqual(store.tail(500).count, 0, "the window is inside the junk line: nothing decodable, nothing invented")
        store.append(Event(kind: .systemSleep, subject: "system"))
        XCTAssertEqual(store.tail(500).map(\.kind), [.systemSleep], "the next real line is seen; the junk before it is skipped, not the seed")
    }

    /// C3-T2: a window that opens on a whole line keeps it; only a torn first line is dropped.
    func testTailDropsOnlyATornFirstLine() throws {
        let store = EventStore(directory: dir)
        let line = try EventLine.encode(Event(kind: .systemWake, subject: "system")) + "\n"
        let perWindow = 524_288 / line.utf8.count + 2
        for _ in 0..<perWindow { store.append(Event(kind: .systemWake, subject: "system")) }
        let got = store.tail(perWindow)
        XCTAssertGreaterThan(got.count, 0)
        let windowHolds = 524_288 / line.utf8.count
        XCTAssertGreaterThanOrEqual(got.count, windowHolds - 1, "at most one torn line is lost from the window")
    }

    /// C3-T5, M18: control characters, bidi overrides and zero-width characters in a device
    /// name are removed before the line is written and when a line is read; letters of any
    /// script pass (security review 2026-10-18, finding 7).
    func testSubjectsAreMadePlainOnWriteAndOnRead() throws {
        let hostile = "Das\u{0000}Key\u{202E}board\u{200B}\u{2066}!\u{001B}"
        let e = Event(kind: .usbAttached, subject: hostile, detail: ["model": "A\u{202D}B"])
        XCTAssertEqual(e.subject, "DasKeyboard!")
        XCTAssertEqual(e.detail["model"], "AB")
        XCTAssertEqual(Event(kind: .usbAttached, subject: "Clé USB 日本語 🙂").subject, "Clé USB 日本語 🙂")
        let line = try EventLine.encode(e)
        XCTAssertFalse(line.contains("\u{202E}"))
        XCTAssertFalse(line.contains("\\u0000"))
        // A line written by something else, with the override still in it.
        let forged = #"{"detail":{},"kind":"usb.attached","subject":"evil\u202Elive","ts":"2025-10-09T08:53:20.250Z"}"#
        XCTAssertEqual(try EventLine.decode(forged).subject, "evillive")
    }
}
