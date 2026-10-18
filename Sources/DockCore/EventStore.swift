// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 11:55 -05:00
// F2-T1 — append-only JSON Lines log with one rotation (FR3, NFR6). Main thread only.
import Foundation

public final class EventStore {
    public enum StoreError: Error, Equatable {
        case open(errno: Int32)
        case shortWrite
    }

    public let url: URL
    public let rotatedURL: URL
    public let maxBytes: Int
    /// The last failure, for the menu. Cleared by the next successful append.
    public private(set) var lastError: String?
    /// Events appended by this process.
    public private(set) var count = 0

    public static func defaultDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/DockWatch", isDirectory: true)
    }

    public init(directory: URL, fileName: String = "events.jsonl", maxBytes: Int = 20_000_000) {
        url = directory.appendingPathComponent(fileName)
        let stem = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        rotatedURL = directory.appendingPathComponent("\(stem).1.\(ext)")
        self.maxBytes = maxBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Returns false, and sets `lastError`, instead of throwing: an unwritable log never
    /// reaches the UI as a crash (NFR6).
    @discardableResult
    public func append(_ event: Event) -> Bool {
        do {
            let line = try EventLine.encode(event) + "\n"
            rotateIfNeeded(adding: line.utf8.count)
            try write(line)
            count += 1
            lastError = nil
            return true
        } catch {
            lastError = "\(error)"
            return false
        }
    }

    private func write(_ line: String) throws {
        // O_APPEND: every write lands at the current end, and this process never truncates
        // the file (M3 breaks exactly this).
        let fd = open(url.path, O_WRONLY | O_APPEND | O_CREAT, 0o644)
        guard fd >= 0 else { throw StoreError.open(errno: errno) }
        defer { close(fd) }
        let bytes = Array(line.utf8)
        let written = bytes.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        guard written == bytes.count else { throw StoreError.shortWrite }
    }

    /// At most one previous file is kept: `events.1.jsonl` is replaced, never appended to.
    private func rotateIfNeeded(adding: Int) {
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int,
              size + adding > maxBytes else { return }
        try? FileManager.default.removeItem(at: rotatedURL)
        try? FileManager.default.moveItem(at: url, to: rotatedURL)
    }
}
