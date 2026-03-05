import SwiftUI
import SwiftData

struct SessionCompleteView: View {

    let log: WorkoutLog
    let session: QueuedSession
    let allExercises: [Exercise]
    let priorLogs: [WorkoutLog]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeloadPrompt = false

    private var prLiftIDs: [UUID] {
        ProgressionEngine.newPRs(in: log, against: priorLogs)
    }

    private var avgRestByTier: [ExerciseTier: Int] {
        ProgressionEngine.averageRest(in: log, exercises: allExercises)
    }

    private var stalledExercises: [Exercise] {
        allExercises.filter { ex in
            ProgressionEngine.isStalled(exerciseID: ex.id, priorLogs: priorLogs + [log])
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    completionHeader
                    statsRow
                    if !prLiftIDs.isEmpty { prCard }
                    restSummaryCard
                    setBreakdownCard
                    if !stalledExercises.isEmpty { stallCard }
                    doneButton
                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xl)
            }
        }
    }

    // MARK: - Header

    private var completionHeader: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.green)

            Text("Session Complete")
                .font(.ironLogDisplay)
                .foregroundColor(AppTheme.textPrimary)

            Text(session.displayName)
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            statTile(
                value: "\(log.sets.count)",
                label: "Sets",
                icon: "dumbbell.fill"
            )
            statTile(
                value: totalVolume,
                label: "Volume (lbs)",
                icon: "scalemass.fill"
            )
            if let duration = log.durationMinutes {
                statTile(
                    value: "\(duration)m",
                    label: "Duration",
                    icon: "clock.fill"
                )
            }
        }
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(.ironLogMicro)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .ironLogCard()
    }

    private var totalVolume: String {
        let vol = log.sets.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        if vol >= 1000 {
            return String(format: "%.1fk", vol / 1000)
        }
        return "\(Int(vol))"
    }

    // MARK: - PR Card

    private var prCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(AppTheme.accent)
                Text("New PRs")
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
            }

            ForEach(prLiftIDs, id: \.self) { exerciseID in
                if let exercise = allExercises.first(where: { $0.id == exerciseID }),
                   let weight = log.sets.filter({ $0.exerciseID == exerciseID }).map(\.weightLbs).max() {
                    HStack {
                        Text(exercise.name)
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("\(Int(weight)) lbs")
                            .font(.ironLogHeadline)
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Rest Summary

    private var restSummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Rest Averages")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(ExerciseTier.allCases, id: \.self) { tier in
                if let avg = avgRestByTier[tier] {
                    let target = tier.restRange
                    let isOnTrack = target.contains(avg)

                    HStack {
                        Text(tier.displayName)
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text(formatTime(avg))
                            .font(.ironLogHeadline)
                            .foregroundColor(isOnTrack ? AppTheme.green : AppTheme.orange)
                        Text("/ \(formatTime(target.lowerBound))–\(formatTime(target.upperBound))")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Set Breakdown

    private var setBreakdownCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Set Breakdown")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            let grouped = Dictionary(grouping: log.sets, by: \.exerciseID)
            ForEach(Array(grouped.keys), id: \.self) { exerciseID in
                if let exercise = allExercises.first(where: { $0.id == exerciseID }),
                   let sets = grouped[exerciseID] {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(exercise.name)
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textPrimary)
                        HStack(spacing: Spacing.sm) {
                            ForEach(sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { set in
                                Text("\(Int(set.weightLbs))×\(set.reps)")
                                    .font(.ironLogCaption)
                                    .foregroundColor(set.hitTarget ? AppTheme.accent : AppTheme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.surface2)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Stall Card

    private var stallCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.orange)
                Text("Progress Stalled")
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text("You haven't made progress on \(stalledExercises.map(\.name).joined(separator: ", ")) in 2+ sessions. A deload can help break through.")
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)

            Button {
                showDeloadPrompt = true
            } label: {
                Text("Review Deload Options")
                    .ironLogSecondaryButton()
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(AppTheme.orange.opacity(0.4), lineWidth: 1)
        )
        .sheet(isPresented: $showDeloadPrompt) {
            DeloadPromptView(session: session)
        }
    }

    // MARK: - Done

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
                .ironLogPrimaryButton()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)m\(seconds % 60 > 0 ? "\(seconds % 60)s" : "")"
        }
        return "\(seconds)s"
    }
}
