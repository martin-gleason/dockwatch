// Created: 2026-10-18 16:54 -05:00 · Edited: 2026-10-18 16:54 -05:00
// F4-T3 — user notifications for dock losses (FR6). Needs a bundle; a bare binary logs instead (RR6).
import Foundation
import UserNotifications
import DockCore

final class LossNotifier {
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    /// Asked once, at the installed app's first launch (D27). The system remembers the answer.
    func requestPermissionOnce() {
        guard Self.isAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, error in
                if let error { log("notification permission: \(error.localizedDescription)") }
            }
        }
    }

    func post(_ flush: LossCoalescer.Flush) {
        guard Self.isAvailable else {
            log("notification (not posted: no bundle): \(flush.title) — \(flush.body)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = flush.title
        content.body = flush.body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { log("notification failed: \(error.localizedDescription)") }
        }
    }
}
