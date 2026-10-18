// Created: 2026-10-18 12:40 -05:00 · Edited: 2026-10-18 12:56 -05:00
import XCTest
@testable import DockCore

/// FR5 — the assertion really exists while held, as `pmset -g assertions` sees it, and is
/// gone when released. A live check on the machine running the tests, not a mock. Only
/// this process's own lines count: the app itself may be holding the same name while the
/// owner's overnight experiment runs (F3 review, finding 1).
final class AssertionControllerTests: XCTestCase {
    /// Lines of `pmset -g assertions` that belong to this process and carry our name.
    private func ourAssertionLines() throws -> Int {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g", "assertions"]
        let out = Pipe()
        p.standardOutput = out
        try p.run()
        p.waitUntilExit()
        let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let mine = "pid \(ProcessInfo.processInfo.processIdentifier)("
        return text.split(separator: "\n").filter { $0.contains(mine) && $0.contains(AssertionController.name) }.count
    }

    /// FR5: held → listed under our pid; released → not listed.
    func testAssertionAppearsInPmsetWhileHeldAndNotAfter() throws {
        let c = AssertionController()
        XCTAssertEqual(try ourAssertionLines(), 0, "nothing of ours before the test")
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.isHeld)
        XCTAssertEqual(try ourAssertionLines(), 1, "pmset lists the assertion while held")
        XCTAssertTrue(c.set(held: false))
        XCTAssertFalse(c.isHeld)
        XCTAssertEqual(try ourAssertionLines(), 0, "gone after release")
    }

    /// FR5: set is idempotent, and reapply re-creates without leaving two behind.
    func testSetIsIdempotentAndReapplyLeavesOne() throws {
        let c = AssertionController()
        defer { c.set(held: false) }
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.set(held: true, reapply: true))
        XCTAssertEqual(try ourAssertionLines(), 1, "exactly one assertion of ours")
    }
}
