// Created: 2026-10-18 11:25 -05:00 · Edited: 2026-10-18 11:25 -05:00
import XCTest
@testable import DockCore

/// C1-T2 — the harness `count` command must see at least one executed test, so the floor
/// has a number to protect before F1 lands real tests. Cites C1, not an FR, on purpose.
final class HarnessSmokeTests: XCTestCase {
    func testHarnessSeesAnExecutedTest() {
        XCTAssertFalse(DockCore.version.isEmpty)
    }
}
