// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 11:55 -05:00
// F2-T1 — one dock event, and its one-line JSON form (FR3, NFR6).
import Foundation

public struct Event: Codable, Equatable {
    public enum Kind: String, Codable, CaseIterable {
        case usbAttached = "usb.attached"
        case usbDetached = "usb.detached"
        case volumeMounted = "volume.mounted"
        case volumeUnmounted = "volume.unmounted"
        case volumeDisappeared = "volume.disappeared"
        case systemSleep = "system.sleep"
        case systemDarkWake = "system.darkwake"
        case systemWake = "system.wake"
        case powerConnected = "power.connected"
        case powerDisconnected = "power.disconnected"
    }

    public let ts: Date
    public let kind: Kind
    /// What the event is about: a product name, a volume name, "system", a power source.
    public let subject: String
    /// Small string facts: vendor/product IDs, BSD name, watts. Never sizes (RR7).
    public let detail: [String: String]

    public init(ts: Date = Date(), kind: Kind, subject: String, detail: [String: String] = [:]) {
        self.ts = ts
        self.kind = kind
        self.subject = subject
        self.detail = detail
    }
}

/// JSON Lines codec. One formatter and one encoder for the process (the F1 review measured
/// a per-line formatter at 130 µs against 1 µs reused).
public enum EventLine {
    static let timestamp: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        e.dateEncodingStrategy = .custom { date, enc in
            var c = enc.singleValueContainer()
            try c.encode(timestamp.string(from: date))
        }
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let s = try dec.singleValueContainer().decode(String.self)
            guard let date = timestamp.date(from: s) else {
                throw DecodingError.dataCorrupted(.init(codingPath: dec.codingPath, debugDescription: "not an ISO 8601 timestamp: \(s)"))
            }
            return date
        }
        return d
    }()

    /// The line without its trailing newline.
    public static func encode(_ event: Event) throws -> String {
        String(decoding: try encoder.encode(event), as: UTF8.self)
    }

    public static func decode(_ line: String) throws -> Event {
        try decoder.decode(Event.self, from: Data(line.utf8))
    }
}
