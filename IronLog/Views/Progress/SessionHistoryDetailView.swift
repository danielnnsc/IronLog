import SwiftUI

struct SessionHistoryDetailView: View {

    let log: WorkoutLog
    let exercises: [Exercise]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header stats
                    HStack(spacing: Spacing.sm) {
                        statTile(value: "\(log.sets.count)", label: "Sets")
                        statTile(value: volume, label: "Volume lbs")
                        if let d = log.durationMinutes {
                            statTile(value: "\(d)m", label: "Duration")
                        }
                    }

                    // Sets per exercise
                    let grouped = Dictionary(grouping: log.sets, by: \.exerciseID)
                    ForEach(Array(grouped.keys), id: \.self) { exerciseID in
                        if let sets = grouped[exerciseID] {
                            exerciseCard(exerciseID: exerciseID, sets: sets)
                        }
                    }

                    if let notes = log.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Notes")
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.textTertiary)
                            Text(notes)
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(Spacing.md)
                        .ironLogCard()
                    }

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
        }
        .navigationTitle(log.queuedSession?.displayName ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var volume: String {
        let v = log.sets.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        return v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.accent)
            Text(label)
                .font(.ironLogMicro)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .ironLogCard()
    }

    private func exerciseCard(exerciseID: UUID, sets: [SetLog]) -> some View {
        let exercise = exercises.first { $0.id == exerciseID }
        let sorted = sets.sorted { $0.setNumber < $1.setNumber }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(exercise?.name ?? "Exercise")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(sorted, id: \.id) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                        .frame(width: 44, alignment: .leading)

                    Text("\(Int(set.weightLbs)) lbs × \(set.reps) reps")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)

                    if let rpe = set.rpe {
                        Text("Difficulty \(rpe)")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: set.hitTarget ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundColor(set.hitTarget ? AppTheme.green : AppTheme.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }
}
