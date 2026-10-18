// Created: 2026-10-18 13:04 -05:00 · Edited: 2026-10-18 13:04 -05:00
// F6-T2 — is this USB disk on the dock? (FR9). Pure; no IOKit.

/// A USB device is on the dock when it hangs off the same host controller as the dock
/// device itself. On Apple silicon the controller is the top byte of the IOUSB location ID:
/// the dock's own Thunderbolt-tunnelled controller on this Mac is `0x02`, the built-in
/// ports are `0x00` and `0x01`. The dock's hubs (`0x02148000`, `0x02240000`) and every disk
/// behind them (`0x02242000`, `0x02230000`) share it.
public enum DockMembership {
    /// Bits below this are the hub-port path; above it, the controller.
    static let controllerShift: UInt32 = 24

    public static func isOnDock(usbLocationID: UInt32, dockLocationID: UInt32) -> Bool {
        (usbLocationID >> controllerShift) == (dockLocationID >> controllerShift)
    }
}
