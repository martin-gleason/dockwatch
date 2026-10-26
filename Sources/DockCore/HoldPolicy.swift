// Created: 2026-10-18 12:40 -05:00 · Edited: 2026-10-26 17:12 -05:00
// F3-T1 — when the Mac should be held out of idle sleep (FR5). Pure; no IOKit.
// F8-T1 — the toggle defaults on (D36).

/// The one rule: hold exactly when the toggle is on and the dock is present. The hold
/// follows the dock tracker with no grace period (RR14 policy in docs/plans/F3.md).
public struct HoldPolicy: Equatable {
    public enum Input: Equatable {
        case toggleChanged(Bool)
        case dockChanged(Bool)
        /// A full wake. macOS may have dropped the assertion across the sleep, so the
        /// answer must be applied again even when it has not changed (NFR8).
        case didWake
    }

    public struct Decision: Equatable {
        public let hold: Bool
        /// True when the controller must re-create the assertion even if it believes it holds one.
        public let reapply: Bool

        public init(hold: Bool, reapply: Bool) {
            self.hold = hold
            self.reapply = reapply
        }
    }

    public private(set) var toggle: Bool
    public private(set) var docked: Bool

    /// F8 (D36): the toggle is on unless the owner has turned it off, so a fresh install
    /// holds from its first launch while docked. The app falls back to this only when no
    /// preference is stored; a stored off stays off. M20 flips it.
    public static let defaultToggle = true

    public init(toggle: Bool = HoldPolicy.defaultToggle, docked: Bool = false) {
        self.toggle = toggle
        self.docked = docked
    }

    public var shouldHold: Bool { toggle && docked }

    public mutating func apply(_ input: Input) -> Decision {
        switch input {
        case .toggleChanged(let on):
            toggle = on
            return Decision(hold: shouldHold, reapply: false)
        case .dockChanged(let present):
            docked = present
            return Decision(hold: shouldHold, reapply: false)
        case .didWake:
            return Decision(hold: shouldHold, reapply: true)
        }
    }
}
