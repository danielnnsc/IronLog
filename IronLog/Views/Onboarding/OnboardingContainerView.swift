import SwiftUI
import SwiftData
import UserNotifications

/// Manages the 6-step onboarding flow and generates the program on completion.
struct OnboardingContainerView: View {

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - State

    @State private var currentStep = 0
    @State private var timeAway: TimeAway = .fewMonths
    @State private var daysPerWeek: Int = 4
    @State private var selectedInjuries: Set<Injury> = []
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .thursday, .friday]
    @State private var weightLbs: Int = 175
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var isGenerating = false
    @State private var generationError: String?

    private let totalSteps = 7

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Step content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(onNext: nextStep)
                        .tag(0)

                    OnboardingTimeAwayView(selection: $timeAway, onNext: nextStep)
                        .tag(1)

                    OnboardingTrainingDaysView(daysPerWeek: $daysPerWeek, onNext: nextStep)
                        .tag(2)

                    OnboardingInjuriesView(selectedInjuries: $selectedInjuries, onNext: nextStep)
                        .tag(3)

                    OnboardingDayPickerView(
                        daysPerWeek: daysPerWeek,
                        selectedDays: $selectedDays,
                        onNext: nextStep
                    )
                    .tag(4)

                    OnboardingBodyStatsView(
                        weightLbs: $weightLbs,
                        heightFeet: $heightFeet,
                        heightInches: $heightInches,
                        onNext: nextStep
                    )
                    .tag(5)

                    OnboardingReviewView(
                        selectedDays: selectedDays,
                        isGenerating: isGenerating,
                        error: generationError,
                        onConfirm: finishOnboarding
                    )
                    .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                AppTheme.surface2
                AppTheme.accent
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Navigation

    private func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation { currentStep += 1 }
    }

    // MARK: - Program Generation

    private func finishOnboarding() {
        guard !isGenerating else { return }
        isGenerating = true
        generationError = nil

        // Enforce days per week matches selection
        var days = Array(selectedDays).sorted()
        if days.count != daysPerWeek {
            days = Array(days.prefix(daysPerWeek))
        }

        let generator = ProgramGenerator(
            modelContext: modelContext,
            scheduledDays: days,
            weeksToGenerate: 8
        )

        Task { @MainActor in
            do {
                try generator.generate()
                await requestNotificationPermission()
                // Persist body stats
                UserDefaults.standard.set(weightLbs, forKey: "userWeightLbs")
                UserDefaults.standard.set(heightFeet, forKey: "userHeightFeet")
                UserDefaults.standard.set(heightInches, forKey: "userHeightInchesRemainder")
                hasCompletedOnboarding = true
            } catch {
                generationError = "Couldn't generate your program. Please try again."
                isGenerating = false
            }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}

// MARK: - Supporting Types

enum TimeAway: String, CaseIterable, Identifiable {
    case weeks       = "A few weeks"
    case fewMonths   = "A few months"
    case sixMonths   = "6+ months"
    case oneYear     = "1+ year"

    var id: String { rawValue }
}

enum Injury: String, CaseIterable, Identifiable {
    case lowerBack  = "Lower Back"
    case knees      = "Knees"
    case shoulders  = "Shoulders"
    case wrists     = "Wrists"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .lowerBack:  return "figure.walk"
        case .knees:      return "figure.run"
        case .shoulders:  return "figure.arms.open"
        case .wrists:     return "hand.raised"
        }
    }
}
