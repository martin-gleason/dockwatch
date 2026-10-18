// Created: 2026-10-18 13:04 -05:00 · Edited: 2026-10-18 13:04 -05:00
import XCTest
@testable import DockCore
import DiskArbitration

/// FR9 — results read as the menu will show them, and a real unmount against a throwaway
/// disk image: refused while a file is open on it, naming this process; done once closed.
final class VolumeEjectorTests: XCTestCase {
    /// FR9: the result text the menu shows.
    func testMenuTextNamesWhatHappened() {
        XCTAssertEqual(EjectResult.done.menuText, "Ejected")
        XCTAssertEqual(EjectResult.blocked(by: ["backupd"]).menuText, "In use by backupd")
        XCTAssertEqual(EjectResult.blocked(by: ["Finder", "backupd"]).menuText, "In use by Finder, backupd")
        XCTAssertEqual(EjectResult.blocked(by: []).menuText, "In use by another process")
        XCTAssertEqual(EjectResult.failed(status: 7, message: "Not mounted").menuText, "Could not eject: Not mounted")
    }

    /// FR9: both spellings of "busy" are busy; other kernel errors read as words.
    func testBusyIsRecognisedInBothEncodings() {
        XCTAssertTrue(VolumeEjector.isBusy(DAReturn(kDAReturnBusy)))
        XCTAssertTrue(VolumeEjector.isBusy(0xC010))
        XCTAssertFalse(VolumeEjector.isBusy(DAReturn(kDAReturnNotMounted)))
        XCTAssertEqual(VolumeEjector.describe(VolumeEjector.unixError(EACCES)), "Permission denied")
    }

    // MARK: live, on a disk image

    private var image: URL!
    private var devEntry: String?
    private var mountPoint: String?

    override func setUpWithError() throws {
        image = FileManager.default.temporaryDirectory.appendingPathComponent("dockwatch-eject-\(UUID().uuidString).dmg")
        _ = try run("/usr/bin/hdiutil", ["create", "-quiet", "-size", "4m", "-fs", "APFS", "-volname", "DWEject", image.path])
        let out = try run("/usr/bin/hdiutil", ["attach", "-nobrowse", "-plist", image.path])
        let plist = try PropertyListSerialization.propertyList(from: Data(out.utf8), format: nil) as? [String: Any]
        for entity in plist?["system-entities"] as? [[String: Any]] ?? [] {
            if let mp = entity["mount-point"] as? String, let dev = entity["dev-entry"] as? String {
                mountPoint = mp
                devEntry = dev
            }
        }
        try XCTSkipIf(devEntry == nil, "hdiutil did not attach a mountable volume")
    }

    override func tearDownWithError() throws {
        if let devEntry { _ = try? run("/usr/bin/hdiutil", ["detach", "-quiet", "-force", devEntry]) }
        try? FileManager.default.removeItem(at: image)
    }

    private func run(_ tool: String, _ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        let out = Pipe()
        p.standardOutput = out
        try p.run()
        p.waitUntilExit()
        return String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }

    private func eject(_ ejector: VolumeEjector) throws -> EjectResult {
        let bsd = String(devEntry!.dropFirst("/dev/".count))
        let done = expectation(description: "eject completes")
        var result: EjectResult?
        try ejector.eject(bsdName: bsd, mountPath: mountPoint) { result = $0; done.fulfill() }
        wait(for: [done], timeout: 15)
        return try XCTUnwrap(result)
    }

    /// FR9: an open file blocks the eject and the blocker is named; closing it lets the eject through.
    func testBusyVolumeIsRefusedAndNamed_thenEjectsWhenFree() throws {
        let ejector = VolumeEjector()
        let file = URL(fileURLWithPath: mountPoint!).appendingPathComponent("held.txt")
        try Data("x".utf8).write(to: file)
        let handle = try FileHandle(forReadingFrom: file)

        let blocked = try eject(ejector)
        guard case .blocked(let names) = blocked else { return XCTFail("expected blocked, got \(blocked)") }
        XCTAssertTrue(names.contains("xctest"), "the blocker is this test process, got \(names)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: mountPoint!), "still mounted: never forced")

        try handle.close()
        XCTAssertEqual(try eject(ejector), .done)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path), "the volume is gone from the path")
    }
}
