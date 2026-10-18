// Created: 2026-10-18 12:40 -05:00 · Edited: 2026-10-18 12:40 -05:00
import XCTest
@testable import DockCore

/// FR5 — the assertion really exists while held, as `pmset -g assertions` sees it, and is
/// gone when released. A live check on the machine running the tests, not a mock.
final class AssertionControllerTests: XCTestCase {
    private func pmsetListsOurAssertion() throws -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g", "assertions"]
        let out = Pipe()
        p.standardOutput = out
        try p.run()
        p.waitUntilExit()
        let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return text.contains(AssertionController.name)
    }

    /// FR5: held → listed; released → not listed.
    func testAssertionAppearsInPmsetWhileHeldAndNotAfter() throws {
        let c = AssertionController()
        XCTAssertFalse(try pmsetListsOurAssertion(), "nothing of ours before the test")
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.isHeld)
        XCTAssertTrue(try pmsetListsOurAssertion(), "pmset lists the assertion while held")
        XCTAssertTrue(c.set(held: false))
        XCTAssertFalse(c.isHeld)
        XCTAssertFalse(try pmsetListsOurAssertion(), "gone after release")
    }

    /// FR5: set is idempotent, and reapply re-creates without leaving two behind.
    func testSetIsIdempotentAndReapplyLeavesOne() throws {
        let c = AssertionController()
        defer { c.set(held: false) }
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.set(held: true))
        XCTAssertTrue(c.set(held: true, reapply: true))
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g", "assertions"]
        let out = Pipe(); p.standardOutput = out
        try p.run(); p.waitUntilExit()
        let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        XCTAssertEqual(text.components(separatedBy: AssertionController.name).count - 1, 1, "exactly one assertion of ours")
    }
}
