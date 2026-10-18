// Created: 2026-10-18 11:40 -05:00 · Edited: 2026-10-18 11:40 -05:00
// F1-T2 — which USB device *is* the dock (FR2, D4).

public struct DockIdentity: Equatable {
    public let vendorID: Int
    public let productID: Int

    public init(vendorID: Int, productID: Int) {
        self.vendorID = vendorID
        self.productID = productID
    }

    /// Razer Thunderbolt 4 Dock Chroma: the device macOS names "Thunderbolt 4 Dock".
    /// The Chroma lighting controller on the same dock enumerates separately as
    /// 0x1532:0x0F21 and is deliberately not this.
    public static let razerThunderbolt4Dock = DockIdentity(vendorID: 0x1532, productID: 0x122E)

    /// Both IDs must match. Vendor alone would make any Razer mouse look like the dock (M4).
    public func matches(_ device: USBDeviceDescriptor) -> Bool {
        device.vendorID == vendorID && device.productID == productID
    }
}
