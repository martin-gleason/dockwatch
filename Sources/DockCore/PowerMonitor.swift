// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 11:55 -05:00
// F2-T3 — charger connect and disconnect with the negotiated watts (FR3, NFR2).
import Foundation
import IOKit.ps

public struct PowerState: Equatable {
    public let external: Bool
    public let watts: Int?
    public let source: String
}

public struct PowerEvent: Equatable {
    public let state: PowerState
    /// Watts of the adapter that was just lost, on a disconnect.
    public let previousWatts: Int?
    /// True for the state read at start, before any change.
    public let initial: Bool
}

public enum PowerMonitorError: Error { case source }

/// Emits only on connect/disconnect transitions, never on battery-percentage ticks.
public final class PowerMonitor {
    public typealias Handler = (PowerEvent) -> Void

    private let handler: Handler
    private let runLoop: CFRunLoop
    private var source: CFRunLoopSource?
    private var last: PowerState?

    public init(runLoop: CFRunLoop = CFRunLoopGetMain(), handler: @escaping Handler) {
        self.runLoop = runLoop
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        guard source == nil else { return }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        guard let src = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            Unmanaged<PowerMonitor>.fromOpaque(ctx).takeUnretainedValue().poll(initial: false)
        }, ctx)?.takeRetainedValue() else { throw PowerMonitorError.source }
        source = src
        CFRunLoopAddSource(runLoop, src, .commonModes)
        poll(initial: true)
    }

    public func stop() {
        guard let source else { return }
        CFRunLoopRemoveSource(runLoop, source, .commonModes)
        self.source = nil
    }

    public static func current() -> PowerState {
        var providing: String?
        if let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() {
            providing = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        }
        let external = providing == (kIOPMACPowerKey as String)
        let details = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        let watts = details?[kIOPSPowerAdapterWattsKey as String] as? Int
        return PowerState(external: external, watts: watts, source: providing ?? "unknown")
    }

    private func poll(initial: Bool) {
        let now = Self.current()
        if initial || now.external != last?.external {
            handler(PowerEvent(state: now, previousWatts: last?.watts, initial: initial))
        }
        last = now
    }
}
