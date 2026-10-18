// Created: 2026-10-18 17:03 -05:00 · Edited: 2026-10-18 17:27 -05:00
// F7-T1 — when the menu bar ring moves, and by how much (D16, D20). Pure; no AppKit.

/// The ring's phase is a fraction of a turn, 0 ..< 1. It is still by default, turns slowly
/// while the hold is in force, and makes one full turn when the dock connects or
/// disconnects. Nothing here ticks: the app asks `tick()` only while `isMoving` is true,
/// at `currentFramesPerSecond`, which is low for the slow turn (the F7 review measured the
/// cost of a menu bar redraw, not of the drawing) and higher only during a flourish.
public struct RingMotion: Equatable {
    /// Frames per second during a flourish.
    public let eventFramesPerSecond: Double
    /// Frames per second during the slow held turn: one frame a second moves the rim
    /// about two pixels at 18 pt, enough to read as motion and nothing more.
    public let heldFramesPerSecond: Double
    /// Seconds for one turn while the hold is in force.
    public let heldTurnSeconds: Double
    /// Seconds for the one turn on connect or disconnect.
    public let eventTurnSeconds: Double

    public private(set) var phase: Double = 0
    public private(set) var held = false
    /// Remaining fraction of the flourish, 0 when none is in progress.
    public private(set) var turnRemaining: Double = 0

    /// Never true; here so M13 can flip it and prove the stillness test has teeth.
    static let movesWhenIdle = false
    /// Far below any frame step (the smallest is 1/720 of a turn); absorbs binary rounding.
    static let epsilon = 1e-9

    public init(eventFramesPerSecond: Double = 12, heldFramesPerSecond: Double = 1,
                heldTurnSeconds: Double = 60, eventTurnSeconds: Double = 1.25) {
        self.eventFramesPerSecond = eventFramesPerSecond
        self.heldFramesPerSecond = heldFramesPerSecond
        self.heldTurnSeconds = heldTurnSeconds
        self.eventTurnSeconds = eventTurnSeconds
    }

    /// True while frames are worth drawing. When false the app must not schedule a tick.
    public var isMoving: Bool { Self.movesWhenIdle || held || turnRemaining > 0 }

    /// The rate the app should tick at right now.
    public var currentFramesPerSecond: Double { turnRemaining > 0 ? eventFramesPerSecond : heldFramesPerSecond }

    /// Releasing the hold sends the ring home (phase 0) with a short turn, so the menu bar
    /// ring matches the Finder icon again instead of resting wherever it stopped.
    public mutating func setHeld(_ on: Bool) {
        if held, !on, turnRemaining == 0, phase > Self.epsilon { turnRemaining = 1 - phase }
        held = on
    }

    /// Connect or disconnect: one full turn that ends at home. While it runs the slow turn
    /// pauses; it resumes afterwards if the hold is still in force.
    public mutating func dockChanged() {
        turnRemaining = 1 + (phase > Self.epsilon ? 1 - phase : 0)
    }

    /// Advances one frame at `currentFramesPerSecond`. Returns the new phase.
    @discardableResult
    public mutating func tick() -> Double {
        var step = 0.0
        if turnRemaining > 0 {
            let s = min(turnRemaining, 1 / (eventTurnSeconds * eventFramesPerSecond))
            turnRemaining -= s
            step += s
            if turnRemaining < Self.epsilon {
                turnRemaining = 0
                phase = 0            // a flourish always lands at home
                return phase
            }
        } else if held {
            step += 1 / (heldTurnSeconds * heldFramesPerSecond)
        }
        phase = (phase + step).truncatingRemainder(dividingBy: 1)
        if phase < Self.epsilon || phase > 1 - Self.epsilon { phase = 0 }
        return phase
    }
}
