// Created: 2026-10-18 13:04 -05:00 · Edited: 2026-10-18 13:55 -05:00
// F6-T1 — unmount a volume through DiskArbitration and say what blocked it (FR9, NFR1).
import Foundation
import DiskArbitration
import Darwin

public enum EjectResult: Equatable {
    case done
    /// Names of processes with files open on the volume, when they could be found.
    case blocked(by: [String])
    case failed(status: Int32, message: String)

    /// One short line for the menu (FR9: "the result is reported").
    public var menuText: String {
        switch self {
        case .done: return "Ejected"
        // libproc shows an unprivileged process only its own user's processes, so Time
        // Machine, Spotlight and other root daemons cannot be named (F6 review, finding 3).
        case .blocked(let names) where names.isEmpty: return "In use by a system process"
        case .blocked(let names): return "In use by \(names.joined(separator: ", "))"
        case .failed(_, let message): return "Could not eject: \(message)"
        }
    }

    public var isDone: Bool { if case .done = self { return true } else { return false } }
}

public enum VolumeEjectorError: Error { case session, noSuchDisk(String) }

/// Unmounts a volume; never forces. A busy volume stays mounted and the caller is told who
/// holds it when that can be known. This is an unmount, not Finder's eject: the disk stays
/// attached so a remount needs no replug (D23).
public final class VolumeEjector {
    public typealias Completion = (EjectResult) -> Void

    private let runLoop: CFRunLoop
    private var session: DASession?

    public init(runLoop: CFRunLoop = CFRunLoopGetMain()) {
        self.runLoop = runLoop
    }

    deinit { stop() }

    public func start() throws {
        guard session == nil else { return }
        guard let s = DASessionCreate(kCFAllocatorDefault) else { throw VolumeEjectorError.session }
        DASessionScheduleWithRunLoop(s, runLoop, CFRunLoopMode.commonModes.rawValue)
        session = s
    }

    public func stop() {
        guard let session else { return }
        DASessionUnscheduleFromRunLoop(session, runLoop, CFRunLoopMode.commonModes.rawValue)
        self.session = nil
    }

    /// Unmounts `bsdName` (for example `disk5s2`). `mountPath` is used only to name the
    /// processes holding it open when the unmount is refused as busy.
    public func eject(bsdName: String, mountPath: String?, completion: @escaping Completion) throws {
        if session == nil { try start() }
        guard let session, let disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, bsdName) else {
            throw VolumeEjectorError.noSuchDisk(bsdName)
        }
        let box = Unmanaged.passRetained(CompletionBox(path: mountPath, completion: completion))
        DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionDefault), { _, dissenter, ctx in
            guard let ctx else { return }
            let box = Unmanaged<CompletionBox>.fromOpaque(ctx).takeRetainedValue()
            box.completion(VolumeEjector.result(from: dissenter, path: box.path))
        }, box.toOpaque())
    }

    private final class CompletionBox {
        let path: String?
        let completion: Completion
        init(path: String?, completion: @escaping Completion) { self.path = path; self.completion = completion }
    }

    static func result(from dissenter: DADissenter?, path: String?) -> EjectResult {
        guard let dissenter else { return .done }
        let status = DADissenterGetStatus(dissenter)
        if isBusy(status), let path {
            return .blocked(by: processesUsing(path: path))
        }
        let text = (DADissenterGetStatusString(dissenter) as String?) ?? describe(status)
        return .failed(status: status, message: text)
    }

    /// DiskArbitration reports a busy volume two ways: its own `kDAReturnBusy`, or the
    /// kernel's `EBUSY` wrapped as a Mach error (`unix_err(EBUSY)` = 0xC010), which is what
    /// an open file on the volume produces on this macOS. Both mean "in use".
    static func isBusy(_ status: DAReturn) -> Bool {
        status == DAReturn(kDAReturnBusy) || status == unixError(EBUSY)
    }

    /// `unix_err(errno)`: Mach system 0, subsystem 3, code = errno.
    static func unixError(_ errno: Int32) -> DAReturn {
        DAReturn((3 << 14) | (errno & 0x3fff))
    }

    /// Words for the codes DiskArbitration hands back without a string (observed: always).
    static func describe(_ status: DAReturn) -> String {
        if (status >> 14) == 3 { return String(cString: strerror(Int32(status & 0x3fff))) }
        let da: [DAReturn: String] = [
            DAReturn(kDAReturnError): "DiskArbitration error",
            DAReturn(kDAReturnBusy): "Busy",
            DAReturn(kDAReturnBadArgument): "Bad argument",
            DAReturn(kDAReturnExclusiveAccess): "Opened for exclusive access",
            DAReturn(kDAReturnNoResources): "No resources",
            DAReturn(kDAReturnNotFound): "Not found",
            DAReturn(kDAReturnNotMounted): "Not mounted",
            DAReturn(kDAReturnNotPermitted): "Not permitted",
            DAReturn(kDAReturnNotPrivileged): "Not privileged",
            DAReturn(kDAReturnNotReady): "Not ready",
            DAReturn(kDAReturnNotWritable): "Not writable",
            DAReturn(kDAReturnUnsupported): "Unsupported",
        ]
        return da[status] ?? String(format: "0x%08x", status)
    }

    /// Processes with files open on the volume at `path`, by name. libproc ships in the SDK
    /// and is what `lsof` uses, but its header calls its interfaces private and subject to
    /// change (RR15), and it lists only this user's processes: root daemons come back as an
    /// empty list, which the menu words as "a system process".
    public static func processesUsing(path: String) -> [String] {
        let flags = UInt32(PROC_LISTPIDSPATH_PATH_IS_VOLUME | PROC_LISTPIDSPATH_EXCLUDE_EVTONLY)
        let needed = proc_listpidspath(UInt32(PROC_ALL_PIDS), 0, path, flags, nil, 0)
        guard needed > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(needed) / MemoryLayout<pid_t>.size + 8)
        let got = pids.withUnsafeMutableBytes { proc_listpidspath(UInt32(PROC_ALL_PIDS), 0, path, flags, $0.baseAddress, Int32($0.count)) }
        guard got > 0 else { return [] }
        let count = Int(got) / MemoryLayout<pid_t>.size
        var names: [String] = []
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        for pid in pids.prefix(count) where pid > 0 {
            let n = proc_name(pid, &buffer, UInt32(buffer.count))
            let name = n > 0 ? String(cString: buffer) : "pid \(pid)"
            if !names.contains(name) { names.append(name) }
        }
        return names.sorted()
    }
}
