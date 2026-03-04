import SwiftUI
import SwiftData
import UserNotifications

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @Query private var settings: [UserSettingsModel]
    @Query private var records: [DailyRecord]

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    private var setting: UserSettingsModel? { settings.first }

    private var todayRecord: DailyRecord? {
        records.first { $0.dateKey == PetLogic.dateKey() }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if authStatus == .denied {
                    permissionBanner
                }

                Image(setting?.lastPoseName ?? PetLogic.actionPoses.first ?? "chick_stretch")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)

                let planned = todayRecord?.plannedCount ?? 0
                let completed = todayRecord?.completedCount ?? 0
                let mood = PetLogic.mood(completed: completed, planned: planned)

                Text("Today: \(completed) / \(planned)")
                    .font(.headline)
                Text("Mood: \(mood.rawValue)")
                    .font(.title3.bold())
                Text(PetLogic.encouragement(for: mood))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if setting?.remindersRunning == true {
                    Button("Stop Reminders", role: .destructive) {
                        stopReminders()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start Reminders") {
                        startReminders()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("PuffPet")
        }
        .task {
            await refreshAuth()
            await refreshTodayRecord()
        }
    }

    private var permissionBanner: some View {
        HStack {
            Image(systemName: "bell.slash.fill")
            Text("Notifications are off. Enable in Settings.")
                .font(.subheadline)
            Spacer()
            Button("Open") {
                notificationManager.openSettings()
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(Color.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
    }

    private func refreshTodayRecord() async {
        guard let setting else { return }
        notificationManager.upsertTodayRecord(context: modelContext, settings: setting, incrementCompleted: false)
        await notificationManager.consumeDeliveredReminderPoseUpdate(settings: setting)
        try? modelContext.save()
    }

    private func startReminders() {
        guard let setting else { return }
        setting.remindersRunning = true
        notificationManager.upsertTodayRecord(context: modelContext, settings: setting, incrementCompleted: false)
        Task {
            await notificationManager.scheduleRollingReminders(settings: setting)
            try? modelContext.save()
        }
    }

    private func stopReminders() {
        guard let setting else { return }
        setting.remindersRunning = false
        Task {
            await notificationManager.clearFutureReminders()
            try? modelContext.save()
        }
    }

    private func refreshAuth() async {
        authStatus = await notificationManager.currentAuthorizationStatus()
    }
}
