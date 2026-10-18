// Created: 2026-10-18 12:40 -05:00 · Edited: 2026-10-18 12:40 -05:00
// F3-T2 — the one lever this app has: an idle-sleep assertion on the Mac (FR5, D3).
import Foundation
import IOKit.pwr_mgt

/// Owns at most one `PreventUserIdleSystemSleep` assertion. Display sleep is untouched;
/// the assertion dies with the process. It cannot touch the dock itself, and nothing here
/// claims otherwise.
public final class AssertionController {
    public static let name = "DockWatch: keeping the Thunderbolt dock awake"
    public static let reason = "The Thunderbolt dock is attached and the owner asked to keep it awake; idle sleep drops its power contract."

    private var id: IOPMAssertionID = 0
    public private(set) var isHeld = false
    public private(set) var lastError: String?

    public init() {}

    deinit { release() }

    /// Idempotent. `reapply` re-creates the assertion even when one is believed held.
    /// Returns true when the resulting state matches the request.
    @discardableResult
    public func set(held: Bool, reapply: Bool = false) -> Bool {
        if held, isHeld, !reapply { return true }
        if !held, !isHeld { return true }
        release()
        if held {
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                Self.name as CFString,
                &id)
            if result == kIOReturnSuccess {
                IOPMAssertionSetProperty(id, kIOPMAssertionHumanReadableReasonKey as CFString, Self.reason as CFString)
                isHeld = true
                lastError = nil
            } else {
                id = 0
                isHeld = false
                lastError = String(format: "IOPMAssertionCreateWithName failed: 0x%08x", result)
            }
        }
        return isHeld == held
    }

    private func release() {
        guard isHeld else { return }
        IOPMAssertionRelease(id)
        id = 0
        isHeld = false
    }
}
