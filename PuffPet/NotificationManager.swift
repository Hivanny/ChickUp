import Foundation
import Combine
import SwiftData
import UIKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    let reminderCategoryId = "PUFFPET_REMINDER_CATEGORY"
    let doneActionId = "PUFFPET_DONE_ACTION"
    let snoozeActionId = "PUFFPET_SNOOZE_ACTION"
    let reminderPrefix = "puffpet.reminder"
    let snoozePrefix = "puffpet.snooze"

    private let center = UNUserNotificationCenter.current()
    private let titleOptions = ["Time to move! 🐥", "Hydration break 💧", "Micro-break time ✨"]
    private let bodyOptions = ["Stand up for 10 seconds.", "Take a sip of water.", "Roll your shoulders and breathe."]

    func configure() {
        center.delegate = self
        registerCategories()
    }

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func clearFutureReminders() async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(reminderPrefix) || $0.hasPrefix(snoozePrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleRollingReminders(settings: UserSettingsModel, hoursAhead: Int = 48) async {
        await clearFutureReminders()
        guard settings.remindersRunning else { return }
        guard settings.endMinutesFromMidnight > settings.startMinutesFromMidnight else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let endWindow = calendar.date(byAdding: .hour, value: max(24, hoursAhead), to: now) else { return }

        var cursor = calendar.startOfDay(for: now)

        while cursor <= endWindow {
            let weekday = calendar.component(.weekday, from: cursor)
            let isWeekday = weekday != 1 && weekday != 7
            if !settings.weekdaysOnly || isWeekday {
                let starts = stride(from: settings.startMinutesFromMidnight, to: settings.endMinutesFromMidnight, by: settings.intervalMinutes)
                for minute in starts {
                    let triggerDate = combine(day: cursor, minuteOfDay: minute, calendar: calendar)
                    if triggerDate >= now && triggerDate <= endWindow {
                        await scheduleReminder(at: triggerDate)
                    }
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }
    }


    func consumeDeliveredReminderPoseUpdate(settings: UserSettingsModel) async {
        let delivered = await center.deliveredNotifications()
        let hasReminderDelivery = delivered.contains { note in
            note.request.identifier.hasPrefix(reminderPrefix) || note.request.identifier.hasPrefix(snoozePrefix)
        }
        if hasReminderDelivery {
            settings.lastPoseName = PetLogic.actionPoses.randomElement() ?? PetLogic.happyPose
            center.removeAllDeliveredNotifications()
        }
    }
    private func scheduleReminder(at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = titleOptions.randomElement() ?? "Time to move! 🐥"
        content.body = bodyOptions.randomElement() ?? "Take a sip of water."
        content.sound = .default
        content.categoryIdentifier = reminderCategoryId

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "\(reminderPrefix).\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleSnooze(after minutes: Int = 10) async {
        let content = UNMutableNotificationContent()
        content.title = "Gentle nudge 🐥"
        content.body = "Snooze is over — quick stretch or sip?"
        content.sound = .default
        content.categoryIdentifier = reminderCategoryId

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let identifier = "\(snoozePrefix).\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func registerCategories() {
        let done = UNNotificationAction(identifier: doneActionId, title: "DONE", options: [.foreground])
        let snooze = UNNotificationAction(identifier: snoozeActionId, title: "SNOOZE 10 MIN", options: [])
        let category = UNNotificationCategory(
            identifier: reminderCategoryId,
            actions: [done, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    private func combine(day: Date, minuteOfDay: Int, calendar: Calendar) -> Date {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: day)
        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: hour,
            minute: minute
        )) ?? day
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let context = appDelegate?.modelContainer?.mainContext,
                  let settings = try? context.fetch(FetchDescriptor<UserSettingsModel>()).first else {
                completionHandler()
                return
            }

            switch response.actionIdentifier {
            case doneActionId:
                upsertTodayRecord(context: context, settings: settings, incrementCompleted: true)
                settings.lastPoseName = PetLogic.nextPose(forMood: .happy)
                try? context.save()
            case snoozeActionId:
                await scheduleSnooze(after: 10)
            default:
                settings.lastPoseName = PetLogic.nextPose(forMood: .normal)
                try? context.save()
            }
            completionHandler()
        }
    }

    func upsertTodayRecord(context: ModelContext, settings: UserSettingsModel, incrementCompleted: Bool) {
        let key = PetLogic.dateKey()
        let predicate = #Predicate<DailyRecord> { $0.dateKey == key }
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        let planned = PetLogic.plannedCount(
            startMinutes: settings.startMinutesFromMidnight,
            endMinutes: settings.endMinutesFromMidnight,
            intervalMinutes: settings.intervalMinutes,
            weekdaysOnly: settings.weekdaysOnly
        )

        let record = (try? context.fetch(descriptor).first) ?? {
            let fresh = DailyRecord(dateKey: key, plannedCount: planned, completedCount: 0)
            context.insert(fresh)
            return fresh
        }()

        record.plannedCount = planned
        if incrementCompleted {
            record.completedCount += 1
        }
    }
}
