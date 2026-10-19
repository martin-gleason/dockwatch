// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 19:20 -05:00
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
        case systemWake = "system.wake"   // full wakes only: dark wakes never reach a user-space app (D18)
        case powerConnected = "power.connected"
        case powerDisconnected = "power.disconnected"
        case volumeEject = "volume.eject"   // FR9: an eject was asked for; detail.result says what happened
        case holdOn = "hold.on"      // D21: the sleep assertion was taken
        case holdOff = "hold.off"    // D21: and released
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
        self.subject = Self.plain(subject)
        self.detail = detail.mapValues(Self.plain)
    }

    /// Decoded lines get the same treatment, so a line written by something else cannot put
    /// a control character into the menu.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(ts: try c.decode(Date.self, forKey: .ts),
                  kind: try c.decode(Kind.self, forKey: .kind),
                  subject: try c.decode(String.self, forKey: .subject),
                  detail: try c.decodeIfPresent([String: String].self, forKey: .detail) ?? [:])
    }

    private enum CodingKeys: String, CodingKey { case ts, kind, subject, detail }

    /// A device or volume name as plain text: C0 and DEL controls, bidi overrides and
    /// isolates, zero-width characters and the byte-order mark are removed. A USB product
    /// string is whatever the device says it is; U+202E can make a menu row read backwards
    /// (security review 2026-10-18, finding 7). Letters of every script pass unchanged.
    public static func plain(_ s: String) -> String {
        String(s.unicodeScalars.filter { u in
            switch u.value {
            case 0x00...0x1F, 0x7F: return false                  // C0 controls, DEL
            case 0x200B...0x200D, 0x2060, 0xFEFF: return false    // zero-width, word joiner, BOM
            case 0x202A...0x202E, 0x2066...0x2069: return false   // bidi embeddings, overrides, isolates
            default: return true
            }
        })
    }
}

/// JSON Lines codec. One formatter and one encoder for the process (the F1 review measured
/// a per-line formatter at 130 µs against 1 µs reused).
public enum EventLine {
    /// The one timestamp formatter in the process; the app's stderr mirror uses it too.
    public static let timestamp: ISO8601DateFormatter = {
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
