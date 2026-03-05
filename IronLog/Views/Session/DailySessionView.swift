import SwiftUI
import SwiftData

/// Read-only overview of a session with ⓘ and swap icons per exercise.
struct DailySessionView: View {

    let session: QueuedSession
    let recentLogs: [WorkoutLog]

    @Query private var exercises: [Exercise]
    @State private var infoExercise: Exercise?
    @State private var swapEntry: TemplateEntry?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerCard
                    exerciseList
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
        }
        .navigationTitle(session.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    if let qs = session.sessionTemplate {
                        ActiveWorkoutView(session: session, recentLogs: recentLogs)
                    }
                } label: {
                    Text("Start")
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .sheet(item: $infoExercise) { ex in
            ExerciseInfoSheet(exercise: ex, onSwap: {
                infoExercise = nil
                // swap logic initiated from info sheet
            })
        }
        .sheet(item: $swapEntry) { entry in
            if let exercise = exercises.first(where: { $0.id == entry.exerciseID }) {
                ExerciseSwapView(entry: entry, currentExercise: exercise)
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if session.isDeload {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(AppTheme.deload)
                    Text("Deload Week — weights at ~50%")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.deload)
                }
            }

            if let date = session.designatedDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.textTertiary)
                    Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if session.isOverdue {
                        Text("Overdue")
                            .font(.ironLogCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.orange)
                    }
                }
            }

            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(AppTheme.textTertiary)
                Text("\(session.sessionTemplate?.entries.count ?? 0) exercises")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(session.sessionTemplate?.sortedEntries ?? [], id: \.id) { entry in
                exerciseCard(entry: entry)
            }
        }
    }

    private func exerciseCard(entry: TemplateEntry) -> some View {
        let exercise = exercises.first { $0.id == entry.exerciseID }
        let weight = recommendedWeight(for: entry, exercise: exercise)

        return HStack(spacing: Spacing.md) {
            // Tier indicator dot
            Circle()
                .fill(tierColor(exercise?.tier))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? "Unknown Exercise")
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Text("\(entry.targetSets) sets × \(entry.targetReps) reps")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)

                    if let weight {
                        Text("·")
                            .foregroundColor(AppTheme.textTertiary)
                        Text(weight)
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.accent)
                    }
                }

                if let tier = exercise?.tier {
                    Text(tier.displayName)
                        .font(.ironLogMicro)
                        .foregroundColor(tierColor(tier))
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }

            Spacer()

            // Info and swap buttons
            HStack(spacing: Spacing.sm) {
                if let exercise {
                    Button {
                        infoExercise = exercise
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .frame(width: 44, height: 44)

                    Button {
                        swapEntry = entry
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Helpers

    private func recommendedWeight(for entry: TemplateEntry, exercise: Exercise?) -> String? {
        guard let exercise else { return nil }
        if exercise.isBodyweight { return "Bodyweight" }

        guard let weight = ProgressionEngine.recommendedWeight(
            for: exercise.id,
            nextSessionNumber: session.sessionNumber,
            exercise: exercise,
            priorLogs: recentLogs
        ) else { return nil }

        if session.isDeload {
            let deloadW = ProgressionEngine.deloadWeight(for: exercise.id, priorLogs: recentLogs) ?? weight * 0.5
            return "\(Int(deloadW)) lbs"
        }

        return "\(Int(weight)) lbs"
    }

    private func tierColor(_ tier: ExerciseTier?) -> Color {
        switch tier {
        case .anchor:    return AppTheme.accent
        case .secondary: return AppTheme.blue
        case .accessory: return AppTheme.textTertiary
        case nil:        return AppTheme.textTertiary
        }
    }
}
