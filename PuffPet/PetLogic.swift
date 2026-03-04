import Foundation

enum PetMood: String {
    case happy = "Happy"
    case normal = "Normal"
    case sleepy = "Sleepy"
    case sad = "Sad"
}

enum PetLogic {
    static let actionPoses = [
        "chick_stretch",
        "chick_listening",
        "chick_standup",
        "chick_reading",
        "chick_takingnote"
    ]
    static let happyPose = "chick_happy"

    static func mood(completed: Int, planned: Int) -> PetMood {
        let rate = Double(completed) / Double(max(planned, 1))
        switch rate {
        case 0.8...:
            return .happy
        case 0.5..<0.8:
            return .normal
        case 0.2..<0.5:
            return .sleepy
        default:
            return .sad
        }
    }

    static func nextPose(forMood mood: PetMood) -> String {
        if mood == .happy, Double.random(in: 0...1) < 0.7 {
            return happyPose
        }
        return actionPoses.randomElement() ?? happyPose
    }

    static func encouragement(for mood: PetMood) -> String {
        switch mood {
        case .happy:
            return "You're crushing it today! Keep fluttering."
        case .normal:
            return "Nice pace! One more tiny break helps a lot."
        case .sleepy:
            return "A short stretch can wake your wings right up."
        case .sad:
            return "Small steps count. Let's do one gentle break now."
        }
    }

    static func plannedCount(
        startMinutes: Int,
        endMinutes: Int,
        intervalMinutes: Int,
        weekdaysOnly: Bool,
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard endMinutes > startMinutes, intervalMinutes > 0 else { return 0 }
        if weekdaysOnly {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 { return 0 }
        }
        return Int(floor(Double(endMinutes - startMinutes) / Double(intervalMinutes)))
    }

    static func dateKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
