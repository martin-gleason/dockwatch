// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 11:32 -05:00
// F1-T2 — what DockCore knows about one USB device. Plain data; no IOKit here.
import Foundation  // String(format:) — F1 review, finding 3

public struct USBDeviceDescriptor: Equatable, Hashable {
    public let vendorID: Int
    public let productID: Int
    public let productName: String?
    public let locationID: UInt32
    /// IORegistry entry ID. Stable for the life of the device; the key that pairs a
    /// termination with the attach that preceded it, when properties are no longer readable.
    public let registryID: UInt64

    public init(vendorID: Int, productID: Int, productName: String?, locationID: UInt32, registryID: UInt64) {
        self.vendorID = vendorID
        self.productID = productID
        self.productName = productName
        self.locationID = locationID
        self.registryID = registryID
    }

    /// `1532:122e "Thunderbolt 4 Dock" @0x2148000` — for logs, never for matching.
    public var summary: String {
        let name = productName.map { " \"\($0)\"" } ?? ""
        return String(format: "%04x:%04x", vendorID, productID) + name + String(format: " @0x%x", locationID)
    }
}

public struct USBEvent: Equatable {
    public enum Kind: String { case attached, detached }
    public let kind: Kind
    public let device: USBDeviceDescriptor

    public init(kind: Kind, device: USBDeviceDescriptor) {
        self.kind = kind
        self.device = device
    }
}
