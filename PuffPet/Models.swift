import Foundation
import SwiftData

@Model
final class UserSettingsModel {
    var startMinutesFromMidnight: Int
    var endMinutesFromMidnight: Int
    var intervalMinutes: Int
    var weekdaysOnly: Bool
    var remindersRunning: Bool
    var lastPoseName: String
    var hasUserCustomized: Bool

    init(
        startMinutesFromMidnight: Int = 9 * 60,
        endMinutesFromMidnight: Int = 17 * 60,
        intervalMinutes: Int = 30,
        weekdaysOnly: Bool = true,
        remindersRunning: Bool = true,
        lastPoseName: String = PetLogic.actionPoses.first ?? "chick_stretch",
        hasUserCustomized: Bool = false
    ) {
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.endMinutesFromMidnight = endMinutesFromMidnight
        self.intervalMinutes = intervalMinutes
        self.weekdaysOnly = weekdaysOnly
        self.remindersRunning = remindersRunning
        self.lastPoseName = lastPoseName
        self.hasUserCustomized = hasUserCustomized
    }
}

@Model
final class DailyRecord {
    var dateKey: String
    var plannedCount: Int
    var completedCount: Int

    init(dateKey: String, plannedCount: Int, completedCount: Int = 0) {
        self.dateKey = dateKey
        self.plannedCount = plannedCount
        self.completedCount = completedCount
    }
}
