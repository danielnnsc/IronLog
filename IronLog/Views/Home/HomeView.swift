import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<QueuedSession> { $0.statusValue == "queued" },
           sort: \QueuedSession.queuePosition)
    private var queue: [QueuedSession]

    @Query(sort: \WorkoutLog.completedAt, order: .reverse)
    private var recentLogs: [WorkoutLog]

    @State private var showingSession = false
    @State private var navigateToActive = false

    var nextSession: QueuedSession? { queue.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        headerSection
                        nextSessionCard
                        if queue.count > 1 { upcomingSection }
                        if !recentLogs.isEmpty { recentSection }
                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("IronLog")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)
                Text(Date.now.formatted(.dateTime.month().day()))
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
            // Streak or total sessions badge
            if !recentLogs.isEmpty {
                VStack(spacing: 2) {
                    Text("\(recentLogs.count)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(AppTheme.accent)
                    Text("sessions")
                        .font(.ironLogMicro)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Next Session Card

    @ViewBuilder
    private var nextSessionCard: some View {
        if let session = nextSession {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(session.isOverdue ? "OVERDUE" : (session.isToday ? "TODAY" : "UP NEXT"))
                            .font(.ironLogMicro)
                            .fontWeight(.bold)
                            .foregroundColor(session.isOverdue ? AppTheme.orange : AppTheme.accent)
                            .tracking(1.5)

                        Text(session.displayName)
                            .font(.ironLogDisplay)
                            .foregroundColor(AppTheme.textPrimary)

                        if let date = session.designatedDate {
                            Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    Spacer()

                    if session.isDeload {
                        deloadBadge
                    }
                }

                // Exercise preview
                if let template = session.sessionTemplate {
                    exercisePreviewList(entries: template.sortedEntries)
                }

                Divider().background(AppTheme.border)

                HStack(spacing: Spacing.sm) {
                    // View session details
                    NavigationLink {
                        DailySessionView(session: session, recentLogs: recentLogs)
                    } label: {
                        Text("View Session")
                            .ironLogSecondaryButton()
                    }

                    // Start workout
                    NavigationLink {
                        ActiveWorkoutView(session: session, recentLogs: recentLogs)
                    } label: {
                        Text("Start Workout")
                            .ironLogPrimaryButton()
                    }
                }
            }
            .padding(Spacing.md)
            .ironLogCard()
        } else {
            emptyStateCard
        }
    }

    private var deloadBadge: some View {
        Text("DELOAD")
            .font(.ironLogMicro)
            .fontWeight(.bold)
            .tracking(1)
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.deload)
            .clipShape(Capsule())
    }

    private func exercisePreviewList(entries: [TemplateEntry]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(entries.prefix(3), id: \.id) { entry in
                // We'd look up exercise by ID in production — show placeholder here
                ExerciseRowPreview(exerciseID: entry.exerciseID,
                                   sets: entry.targetSets,
                                   reps: entry.targetReps)
            }
            if entries.count > 3 {
                Text("+\(entries.count - 3) more exercises")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.green)
            Text("All caught up!")
                .font(.ironLogTitle)
                .foregroundColor(AppTheme.textPrimary)
            Text("No sessions in your queue. Check back on your next scheduled day.")
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .ironLogCard()
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Coming Up")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textSecondary)

            ForEach(Array(queue.dropFirst().prefix(3))) { session in
                upcomingRow(session: session)
            }
        }
    }

    private func upcomingRow(session: QueuedSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textPrimary)
                if let date = session.designatedDate {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).month().day()))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textSecondary)

            ForEach(recentLogs.prefix(3)) { log in
                recentLogRow(log: log)
            }
        }
    }

    private func recentLogRow(log: WorkoutLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.queuedSession?.displayName ?? "Session")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textPrimary)
                Text(log.completedAt.formatted(.dateTime.weekday(.abbreviated).month().day()))
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.green)
        }
        .padding(Spacing.md)
        .ironLogCard()
    }
}

// MARK: - Exercise Row Preview

struct ExerciseRowPreview: View {
    let exerciseID: UUID
    let sets: Int
    let reps: String

    @Query private var exercises: [Exercise]

    var exercise: Exercise? {
        exercises.first { $0.id == exerciseID }
    }

    var body: some View {
        HStack {
            Text(exercise?.name ?? "Exercise")
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text("\(sets)×\(reps)")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
        }
    }
}
