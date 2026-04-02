import SwiftUI
import SwiftData

/// Entry point that routes to Onboarding or the main tab interface.
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .task {
            #if DEBUG
            if CommandLine.arguments.contains("-devSeed") {
                try? DevSeeder.seed(in: modelContext)
                return
            }
            #endif
            // Seed exercises on every launch (safe — exits immediately if already seeded)
            try? await MainActor.run {
                try DataSeeder.seedExercisesIfNeeded(in: modelContext)
            }
        }
    }
}
