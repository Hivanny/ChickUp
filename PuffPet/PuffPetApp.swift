import SwiftUI
import UIKit
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    var modelContainer: ModelContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationManager.shared.configure()
        return true
    }
}

@main
struct PuffPetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var notificationManager = NotificationManager.shared

    private let modelContainer: ModelContainer = {
        let schema = Schema([UserSettingsModel.self, DailyRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .environmentObject(notificationManager)
                .task {
                    appDelegate.modelContainer = modelContainer
                    await bootstrapIfNeeded()
                }
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        let context = modelContainer.mainContext
        let settings = (try? context.fetch(FetchDescriptor<UserSettingsModel>()).first) ?? {
            let s = UserSettingsModel()
            context.insert(s)
            return s
        }()

        NotificationManager.shared.upsertTodayRecord(context: context, settings: settings, incrementCompleted: false)
        try? context.save()

        let granted = await notificationManager.requestPermission()
        if granted {
            await notificationManager.scheduleRollingReminders(settings: settings)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
        }
    }
}
