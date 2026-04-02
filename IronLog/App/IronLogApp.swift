import SwiftUI
import SwiftData

@main
struct IronLogApp: App {

    let container: ModelContainer

    init() {
        _ = NotificationManager.shared // registers UNUserNotificationCenterDelegate
        do {
            let schema = Schema([
                Exercise.self,
                Program.self,
                SessionTemplate.self,
                TemplateEntry.self,
                QueuedSession.self,
                WorkoutLog.self,
                SetLog.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
