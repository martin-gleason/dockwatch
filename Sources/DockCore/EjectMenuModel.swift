// Created: 2026-10-18 13:55 -05:00 · Edited: 2026-10-18 13:55 -05:00
// F6-T3 — what the Dock Volumes section shows (FR9: "the result is reported"). Pure.

import Foundation

/// Rows for the menu: every mounted dock volume, plus a volume that was just ejected so its
/// result can be seen (F6 review, finding 1). A result is cleared the moment its volume
/// mounts again, so "Ejected" is never shown beside a mounted drive (finding 2).
public struct EjectMenuModel: Equatable {
    public struct Row: Equatable {
        public let bsdName: String
        public let title: String
        public let status: String?
        /// False for a row that only reports a result; it has no action.
        public let isEjectable: Bool
    }

    public struct Result: Equatable {
        public let title: String
        public let text: String
        public let at: Date
    }

    /// Whether a result outlives its volume's unmount. Always true; here so M10 can flip it.
    static let showUnmounted = true

    public let lifetime: TimeInterval
    public private(set) var results: [String: Result] = [:]

    public init(lifetime: TimeInterval = 60) {
        self.lifetime = lifetime
    }

    public mutating func record(bsdName: String, title: String, text: String, at: Date = Date()) {
        results[bsdName] = Result(title: title, text: text, at: at)
    }

    /// A volume that mounts again has no current result.
    public mutating func volumeMounted(bsdName: String) {
        results.removeValue(forKey: bsdName)
    }

    /// Mounted volumes first (with any recent result), then recent results for volumes that
    /// are no longer mounted, as rows without an action. Expired results are dropped.
    public mutating func rows(mounted: [(bsdName: String, title: String)], now: Date = Date()) -> [Row] {
        results = results.filter { now.timeIntervalSince($0.value.at) < lifetime }
        var rows = mounted.map { Row(bsdName: $0.bsdName, title: $0.title, status: results[$0.bsdName]?.text, isEjectable: true) }
        let mountedSet = Set(mounted.map(\.bsdName))
        for (bsd, r) in results.sorted(by: { $0.value.at < $1.value.at }) where Self.showUnmounted && !mountedSet.contains(bsd) {
            rows.append(Row(bsdName: bsd, title: r.title, status: r.text, isEjectable: false))
        }
        return rows
    }
}
