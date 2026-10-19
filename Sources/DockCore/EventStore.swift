// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 19:20 -05:00
// F2-T1 — append-only JSON Lines log with one rotation (FR3, NFR6). Main thread only.
import Foundation

public final class EventStore {
    public enum StoreError: Error, Equatable, CustomStringConvertible {
        case open(errno: Int32)
        case write(errno: Int32)
        case shortWrite(wrote: Int, of: Int)
        case rotate(String)
        case notRegularFile

        public var description: String {
            switch self {
            case .open(let e): return "cannot open log: \(String(cString: strerror(e)))"
            case .write(let e): return "cannot write log: \(String(cString: strerror(e)))"
            case .shortWrite(let w, let n): return "short write: \(w) of \(n) bytes"
            case .rotate(let why): return "cannot rotate log: \(why)"
            case .notRegularFile: return "log path is not a regular file"
            }
        }
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
            let rotation = rotateIfNeeded(adding: line.utf8.count)
            try write(line)
            count += 1
            lastError = rotation   // nil unless the rotation failed; the line still landed
            return rotation == nil
        } catch {
            lastError = "\(error)"
            return false
        }
    }

    /// The last `n` events in the file, oldest first. Reads at most the final 512 KB. A line
    /// that does not decode (a future kind, a torn write) is skipped, not fatal.
    public func tail(_ n: Int) -> [Event] {
        guard let fd = try? openRegularFile(O_RDONLY) else { return [] }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let start = size > 524_288 ? size - 524_288 : 0
        try? handle.seek(toOffset: start)
        let data = (try? handle.readToEnd()) ?? Data()
        var lines = String(decoding: data, as: UTF8.self).split(separator: "\n", omittingEmptySubsequences: true)
        // A window that starts mid-file usually opens on a torn line; a torn line never decodes,
        // so the compactMap drops it, and a whole first line is kept. Nothing is removed on a
        // guess (security review 2026-10-18, finding 6).
        return lines.suffix(n).compactMap { try? EventLine.decode(String($0)) }
    }

    private func endsWithNewline(_ fd: Int32) throws -> Bool {
        var st = stat()
        guard fstat(fd, &st) == 0 else { throw StoreError.open(errno: errno) }
        guard st.st_size > 0 else { return true }
        let rfd = try openRegularFile(O_RDONLY)
        defer { close(rfd) }
        var last: UInt8 = 0
        return pread(rfd, &last, 1, st.st_size - 1) == 1 && last == UInt8(ascii: "\n")
    }

    /// `O_NOFOLLOW`, named so M15 can drop it and prove the symlink test has teeth.
    static let noFollow = O_NOFOLLOW

    /// Opens the log without following a symlink and refuses anything but a regular file, so
    /// a link or a directory planted at the path is reported, never written through or read
    /// (security review 2026-10-18, finding 6). The caller closes the descriptor.
    private func openRegularFile(_ flags: Int32) throws -> Int32 {
        let fd = open(url.path, flags | Self.noFollow, 0o644)
        guard fd >= 0 else { throw StoreError.open(errno: errno) }
        var st = stat()
        guard fstat(fd, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG else {
            close(fd)
            throw StoreError.notRegularFile
        }
        return fd
    }

    private func write(_ line: String) throws {
        // O_APPEND: every write lands at the current end, and this process never truncates
        // the file (M3 breaks exactly this).
        let fd = try openRegularFile(O_WRONLY | O_APPEND | O_CREAT)
        defer { close(fd) }
        // Always start on a fresh line: an unterminated write by something else must not swallow
        // the next event into itself (found by the C3-T2 test).
        var bytes = Array(line.utf8)
        if try !endsWithNewline(fd) { bytes.insert(UInt8(ascii: "\n"), at: 0) }
        let written = bytes.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        guard written >= 0 else { throw StoreError.write(errno: errno) }
        guard written == bytes.count else { throw StoreError.shortWrite(wrote: written, of: bytes.count) }
    }

    /// At most one previous file is kept: `events.1.jsonl` is replaced, never appended to.
    /// Returns a message when the rotation could not happen, so the cap is never silently
    /// exceeded (F2 review).
    private func rotateIfNeeded(adding: Int) -> String? {
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int,
              size + adding > maxBytes else { return nil }
        do {
            if FileManager.default.fileExists(atPath: rotatedURL.path) {
                try FileManager.default.removeItem(at: rotatedURL)
            }
            try FileManager.default.moveItem(at: url, to: rotatedURL)
            return nil
        } catch {
            return StoreError.rotate(error.localizedDescription).description
        }
    }
}
