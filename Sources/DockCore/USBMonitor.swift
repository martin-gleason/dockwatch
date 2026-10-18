// Created: 2026-10-18 11:20 -05:00 · Edited: 2026-10-18 12:15 -05:00
// F1-T3 — USB attach/detach straight from IOKit, no polling (FR2, NFR1, NFR2).

import Foundation
import IOKit

public enum USBMonitorError: Error, Equatable {
    case notificationPort
    case matching(kern_return_t)
}

/// Delivers a `USBEvent` for every `IOUSBHostDevice` that appears or terminates.
/// On `start()` it also delivers one `.attached` per device already present, so a launch
/// while docked is seen (FR2). Events arrive on the run loop given at init (main by default).
public final class USBMonitor {
    public typealias Handler = (USBEvent) -> Void

    private let handler: Handler
    private let runLoop: CFRunLoop
    private var port: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    /// Descriptors by registry entry ID. A terminating device may already have lost its
    /// properties, so the detach event is built from what was read at attach.
    private var known: [UInt64: USBDeviceDescriptor] = [:]

    public init(runLoop: CFRunLoop = CFRunLoopGetMain(), handler: @escaping Handler) {
        self.runLoop = runLoop
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        guard port == nil else { return }
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else {
            throw USBMonitorError.notificationPort
        }
        self.port = port
        let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        // Common modes, not default: AppKit tracks an open menu in the event-tracking mode,
        // and a default-mode-only source is not serviced until the menu closes (F1 review).
        CFRunLoopAddSource(runLoop, source, .commonModes)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        // Each IOServiceAddMatchingNotification consumes one reference to its matching
        // dictionary, so each call gets its own.
        var kr = IOServiceAddMatchingNotification(
            port, kIOFirstMatchNotification, IOServiceMatching("IOUSBHostDevice"),
            { refcon, iterator in
                guard let refcon else { return }
                Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue().drain(iterator, kind: .attached)
            }, refcon, &addedIterator)
        guard kr == KERN_SUCCESS else { stop(); throw USBMonitorError.matching(kr) }
        drain(addedIterator, kind: .attached, initial: true)   // primes with what is present, and arms

        kr = IOServiceAddMatchingNotification(
            port, kIOTerminatedNotification, IOServiceMatching("IOUSBHostDevice"),
            { refcon, iterator in
                guard let refcon else { return }
                Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue().drain(iterator, kind: .detached)
            }, refcon, &removedIterator)
        guard kr == KERN_SUCCESS else { stop(); throw USBMonitorError.matching(kr) }
        drain(removedIterator, kind: .detached)  // empty at start; the call is what arms it
    }

    public func stop() {
        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        if let port {
            let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
            IONotificationPortDestroy(port)
            self.port = nil
        }
    }

    private func drain(_ iterator: io_iterator_t, kind: USBEvent.Kind, initial: Bool = false) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }
            var entryID: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &entryID)
            switch kind {
            case .attached:
                let device = Self.describe(service, registryID: entryID)
                known[entryID] = device
                handler(USBEvent(kind: .attached, device: device, initial: initial))
            case .detached:
                let device = known.removeValue(forKey: entryID) ?? Self.describe(service, registryID: entryID)
                handler(USBEvent(kind: .detached, device: device))
            }
        }
    }

    private static func describe(_ service: io_service_t, registryID: UInt64) -> USBDeviceDescriptor {
        func property(_ key: String) -> AnyObject? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        func int(_ key: String) -> Int? { (property(key) as? NSNumber)?.intValue }
        return USBDeviceDescriptor(
            vendorID: int("idVendor") ?? 0,
            productID: int("idProduct") ?? 0,
            productName: property("USB Product Name") as? String,
            locationID: UInt32(truncatingIfNeeded: int("locationID") ?? 0),
            registryID: registryID)
    }
}
