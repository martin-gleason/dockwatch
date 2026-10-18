// Created: 2026-10-18 17:03 -05:00 · Edited: 2026-10-18 17:03 -05:00
// F7-T1 — when the menu bar ring moves, and by how much (D16, D20). Pure; no AppKit.

/// The ring's phase is a fraction of a turn, 0 ..< 1. It is still by default, turns slowly
/// while the hold is in force, and makes one full turn when the dock connects or
/// disconnects. Nothing here ticks: the app asks `tick()` only while `isMoving` is true.
public struct RingMotion: Equatable {
    /// Frames per second the app drives while moving; the phase step is derived from it.
    public let framesPerSecond: Double
    /// Seconds for one turn while the hold is in force (slow, so it reads as "alive", not busy).
    public let heldTurnSeconds: Double
    /// Seconds for the one turn on connect or disconnect.
    public let eventTurnSeconds: Double

    public private(set) var phase: Double = 0
    public private(set) var held = false
    /// Remaining fraction of the one-turn flourish, 0 when none is in progress.
    public private(set) var turnRemaining: Double = 0

    public init(framesPerSecond: Double = 12, heldTurnSeconds: Double = 60, eventTurnSeconds: Double = 1.2) {
        self.framesPerSecond = framesPerSecond
        self.heldTurnSeconds = heldTurnSeconds
        self.eventTurnSeconds = eventTurnSeconds
    }

    /// Never true; here so M13 can flip it and prove the stillness test has teeth.
    static let movesWhenIdle = false
    /// Far below any frame step (the smallest is 1/720 of a turn); absorbs binary rounding.
    static let epsilon = 1e-9

    /// True while frames are worth drawing. When false the app must not schedule a tick.
    public var isMoving: Bool { Self.movesWhenIdle || held || turnRemaining > 0 }

    public mutating func setHeld(_ on: Bool) { held = on }

    /// Connect or disconnect: one full turn, on top of whatever else is happening.
    public mutating func dockChanged() { turnRemaining = 1 }

    /// Advances one frame. Returns the new phase.
    @discardableResult
    public mutating func tick() -> Double {
        var step = 0.0
        if turnRemaining > 0 {
            let s = min(turnRemaining, 1 / (eventTurnSeconds * framesPerSecond))
            turnRemaining -= s
            if turnRemaining < Self.epsilon { turnRemaining = 0 }   // ten tenths add up to one
            step += s
        } else if held {
            step += 1 / (heldTurnSeconds * framesPerSecond)
        }
        phase = (phase + step).truncatingRemainder(dividingBy: 1)
        if phase < Self.epsilon || phase > 1 - Self.epsilon { phase = 0 }
        return phase
    }
}
