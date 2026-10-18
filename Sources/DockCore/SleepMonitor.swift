// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 11:55 -05:00
// F2-T3 — sleep, dark wake and wake from the power management root domain (FR3, NFR8).
import Foundation
import IOKit
import IOKit.pwr_mgt
import CoreGraphics

public struct SleepEvent: Equatable {
    public enum Kind: Equatable { case willSleep, darkWake, wake }
    public let kind: Kind
}

public enum SleepMonitorError: Error { case register }

/// Registers for system power messages. Always acknowledges a sleep request immediately,
/// so this app can never delay sleep. Dark wake is told from full wake by whether the main
/// display is asleep at power-on: the public API does not say which kind of wake this is.
public final class SleepMonitor {
    public typealias Handler = (SleepEvent) -> Void

    // IOMessage.h defines these with a function-like macro Swift does not import:
    // iokit_common_msg(x) == 0xe0000000 | x.
    static let canSystemSleep: UInt32 = 0xe000_0270
    static let systemWillSleep: UInt32 = 0xe000_0280
    static let systemWillNotSleep: UInt32 = 0xe000_0290
    static let systemHasPoweredOn: UInt32 = 0xe000_0300
    static let systemWillPowerOn: UInt32 = 0xe000_0320

    private let handler: Handler
    private let runLoop: CFRunLoop
    private var rootPort: io_connect_t = 0
    private var notifyPort: IONotificationPortRef?
    private var notifier: io_object_t = 0

    public init(runLoop: CFRunLoop = CFRunLoopGetMain(), handler: @escaping Handler) {
        self.runLoop = runLoop
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        guard rootPort == 0 else { return }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        rootPort = IORegisterForSystemPower(ctx, &notifyPort, { ctx, _, messageType, argument in
            guard let ctx else { return }
            Unmanaged<SleepMonitor>.fromOpaque(ctx).takeUnretainedValue().handle(messageType, argument)
        }, &notifier)
        guard rootPort != 0, let notifyPort else { throw SleepMonitorError.register }
        CFRunLoopAddSource(runLoop, IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(), .commonModes)
    }

    public func stop() {
        guard rootPort != 0 else { return }
        if let notifyPort {
            CFRunLoopRemoveSource(runLoop, IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(), .commonModes)
        }
        IODeregisterForSystemPower(&notifier)
        IOServiceClose(rootPort)
        if let notifyPort { IONotificationPortDestroy(notifyPort) }
        rootPort = 0
        self.notifyPort = nil
    }

    private func handle(_ type: UInt32, _ argument: UnsafeMutableRawPointer?) {
        switch type {
        case Self.canSystemSleep:
            IOAllowPowerChange(rootPort, Int(bitPattern: argument))
        case Self.systemWillSleep:
            handler(SleepEvent(kind: .willSleep))
            IOAllowPowerChange(rootPort, Int(bitPattern: argument))
        case Self.systemHasPoweredOn:
            let displayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) != 0
            handler(SleepEvent(kind: displayAsleep ? .darkWake : .wake))
        default:
            break
        }
    }
}
