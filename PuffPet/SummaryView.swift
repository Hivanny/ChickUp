import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var records: [DailyRecord]

    var body: some View {
        let today = records.first { $0.dateKey == PetLogic.dateKey() }
        let completed = today?.completedCount ?? 0
        let planned = today?.plannedCount ?? 0
        let mood = PetLogic.mood(completed: completed, planned: planned)

        NavigationStack {
            VStack(spacing: 20) {
                Text("Today's Summary")
                    .font(.title2.bold())
                Text("Completed: \(completed)")
                Text("Planned: \(planned)")
                Text("Mood trend: \(mood.rawValue)")
                    .font(.headline)
                Text(summaryMessage(completed: completed, planned: planned))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Summary")
        }
    }

    private func summaryMessage(completed: Int, planned: Int) -> String {
        if completed == 0 {
            return "Let's catch your first little break — PuffPet believes in you!"
        }
        if completed >= planned {
            return "Amazing consistency today. Your chick is doing a happy dance!"
        }
        return "Nice momentum! A couple more breaks and you're golden."
    }
}
