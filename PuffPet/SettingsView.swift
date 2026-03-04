import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @Query private var settings: [UserSettingsModel]

    @State private var startTime = Date.now
    @State private var endTime = Date.now
    @State private var interval = 30
    @State private var weekdaysOnly = true
    @State private var validationMessage: String?

    private let intervals = [20, 30, 45, 60]

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)

                Picker("Interval", selection: $interval) {
                    ForEach(intervals, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }

                Toggle("Weekdays only", isOn: $weekdaysOnly)

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Settings")
        }
        .onAppear(perform: loadFromSettings)
    }

    private func loadFromSettings() {
        guard let setting = settings.first else { return }
        startTime = date(from: setting.startMinutesFromMidnight)
        endTime = date(from: setting.endMinutesFromMidnight)
        interval = setting.intervalMinutes
        weekdaysOnly = setting.weekdaysOnly
    }

    private func save() {
        guard let setting = settings.first else { return }
        let startMins = minutes(from: startTime)
        let endMins = minutes(from: endTime)

        guard endMins > startMins else {
            validationMessage = "End time must be later than start time."
            return
        }
        validationMessage = nil

        setting.startMinutesFromMidnight = startMins
        setting.endMinutesFromMidnight = endMins
        setting.intervalMinutes = interval
        setting.weekdaysOnly = weekdaysOnly
        setting.hasUserCustomized = true

        notificationManager.upsertTodayRecord(context: modelContext, settings: setting, incrementCompleted: false)

        Task {
            await notificationManager.scheduleRollingReminders(settings: setting)
            try? modelContext.save()
        }
    }

    private func minutes(from date: Date) -> Int {
        let comp = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comp.hour ?? 0) * 60 + (comp.minute ?? 0)
    }

    private func date(from minuteOfDay: Int) -> Date {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}
