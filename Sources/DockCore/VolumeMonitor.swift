// Created: 2026-10-18 11:55 -05:00 · Edited: 2026-10-18 12:15 -05:00
// F2-T2 — external volume mount, unmount and unclean disappearance from DiskArbitration (FR3, NFR2).
import Foundation
import DiskArbitration
import IOKit

public struct VolumeInfo: Equatable {
    public let name: String
    public let bsdName: String
    public let path: String?
    /// Nil when DiskArbitration gives no answer, which is what disk images look like.
    public let isInternal: Bool?
    public let protocolName: String?
    public let model: String?
    /// IOUSB location ID of the USB device the disk hangs off, when it is a USB disk.
    /// F6 uses it to decide "on the dock"; recorded here so the log carries it (RR14).
    public let usbLocationID: UInt32?
}

public struct VolumeEvent: Equatable {
    public enum Kind: Equatable { case mounted, unmounted, disappeared }
    public let kind: Kind
    public let volume: VolumeInfo
    /// True for volumes that were already mounted when the monitor started.
    public let initial: Bool
}

public enum VolumeMonitorError: Error { case session }

/// Tracks mounted external volumes. A clean eject arrives as a description change that
/// drops the mount path (`.unmounted`); a cable pull arrives as a disappearance while still
/// mounted (`.disappeared`). Time Machine's own mounts and simulator images are ignored.
public final class VolumeMonitor {
    public typealias Handler = (VolumeEvent) -> Void

    private let handler: Handler
    private let runLoop: CFRunLoop
    private var session: DASession?
    private var mounted: [String: VolumeInfo] = [:]   // by BSD name
    private var startedAt = Date.distantPast

    public init(runLoop: CFRunLoop = CFRunLoopGetMain(), handler: @escaping Handler) {
        self.runLoop = runLoop
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        guard session == nil else { return }
        guard let session = DASessionCreate(kCFAllocatorDefault) else { throw VolumeMonitorError.session }
        self.session = session
        startedAt = Date()
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        // DiskArbitration replays "appeared" for every existing disk right after registration,
        // which is how launch-time volumes are seen without polling.
        DARegisterDiskAppearedCallback(session, nil, { disk, ctx in
            guard let ctx else { return }
            Unmanaged<VolumeMonitor>.fromOpaque(ctx).takeUnretainedValue().appeared(disk)
        }, ctx)
        DARegisterDiskDescriptionChangedCallback(session, nil, [kDADiskDescriptionVolumePathKey] as CFArray, { disk, _, ctx in
            guard let ctx else { return }
            Unmanaged<VolumeMonitor>.fromOpaque(ctx).takeUnretainedValue().changed(disk)
        }, ctx)
        DARegisterDiskDisappearedCallback(session, nil, { disk, ctx in
            guard let ctx else { return }
            Unmanaged<VolumeMonitor>.fromOpaque(ctx).takeUnretainedValue().disappeared(disk)
        }, ctx)
        DASessionScheduleWithRunLoop(session, runLoop, CFRunLoopMode.commonModes.rawValue)
    }

    public func stop() {
        guard let session else { return }
        DASessionUnscheduleFromRunLoop(session, runLoop, CFRunLoopMode.commonModes.rawValue)
        self.session = nil
    }

    // MARK: callbacks (main run loop)

    private func appeared(_ disk: DADisk) {
        guard let info = Self.describe(disk), info.path != nil, Self.isRelevant(info) else { return }
        mounted[info.bsdName] = info
        handler(VolumeEvent(kind: .mounted, volume: info, initial: Date().timeIntervalSince(startedAt) < 2))
    }

    private func changed(_ disk: DADisk) {
        guard let info = Self.describe(disk) else { return }
        let was = mounted[info.bsdName]
        if info.path != nil, was == nil, Self.isRelevant(info) {
            mounted[info.bsdName] = info
            handler(VolumeEvent(kind: .mounted, volume: info, initial: false))
        } else if info.path == nil, let was {
            mounted.removeValue(forKey: info.bsdName)
            handler(VolumeEvent(kind: .unmounted, volume: was, initial: false))
        }
    }

    private func disappeared(_ disk: DADisk) {
        guard let bsd = DADiskGetBSDName(disk).map({ String(cString: $0) }),
              let was = mounted.removeValue(forKey: bsd) else { return }
        handler(VolumeEvent(kind: .disappeared, volume: was, initial: false))
    }

    // MARK: description

    /// An external device with a mount path. A disk image has no `DADeviceInternal` key and
    /// a "Virtual Interface" protocol, and is not a device (F2 review).
    static func isRelevant(_ v: VolumeInfo) -> Bool {
        guard v.isInternal == false, let path = v.path, v.protocolName != "Virtual Interface" else { return false }
        if path.contains("/.timemachine/") || path.contains("com.apple.TimeMachine") { return false }
        return true
    }

    private static func describe(_ disk: DADisk) -> VolumeInfo? {
        guard let d = DADiskCopyDescription(disk) as? [String: Any],
              let bsd = d[kDADiskDescriptionMediaBSDNameKey as String] as? String else { return nil }
        let path = (d[kDADiskDescriptionVolumePathKey as String] as? URL)?.path
        return VolumeInfo(
            name: d[kDADiskDescriptionVolumeNameKey as String] as? String ?? bsd,
            bsdName: bsd,
            path: path,
            isInternal: d[kDADiskDescriptionDeviceInternalKey as String] as? Bool,
            protocolName: d[kDADiskDescriptionDeviceProtocolKey as String] as? String,
            model: d[kDADiskDescriptionDeviceModelKey as String] as? String,
            usbLocationID: usbLocation(of: disk))
    }

    /// Walks the IORegistry parents of the disk's media until an IOUSBHostDevice and reads
    /// its locationID. Nil for non-USB disks.
    private static func usbLocation(of disk: DADisk) -> UInt32? {
        var entry = DADiskCopyIOMedia(disk)
        guard entry != 0 else { return nil }
        defer { if entry != 0 { IOObjectRelease(entry) } }
        for _ in 0..<32 {
            if IOObjectConformsTo(entry, "IOUSBHostDevice") != 0 {
                let v = IORegistryEntryCreateCFProperty(entry, "locationID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
                return (v as? NSNumber).map { UInt32(truncatingIfNeeded: $0.intValue) }
            }
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS, parent != 0 else { return nil }
            IOObjectRelease(entry)
            entry = parent
        }
        return nil
    }
}
