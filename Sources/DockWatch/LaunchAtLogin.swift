// Created: 2026-10-18 14:29 -05:00 · Edited: 2026-10-18 14:29 -05:00
// F5-T2 — "Launch at Login" through ServiceManagement (FR7). Only meaningful from a bundle.
import Foundation
import ServiceManagement

enum LaunchAtLogin {
    /// A bare `swift run` binary has no bundle identifier; the system cannot register it.
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// Returns a message for the menu when the request did not take, nil when it did.
    @discardableResult
    static func set(enabled: Bool) -> String? {
        guard isAvailable else { return "Launch at Login needs the installed app, not a swift run binary" }
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            return "Launch at Login: \(error.localizedDescription)"
        }
        switch SMAppService.mainApp.status {
        case .requiresApproval:
            // The user turned login items off for this app in System Settings; the system wants them to re-allow it there.
            SMAppService.openSystemSettingsLoginItems()
            return "Launch at Login needs your approval in System Settings → General → Login Items"
        default:
            return nil
        }
    }
}
