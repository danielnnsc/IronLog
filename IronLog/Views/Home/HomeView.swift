import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<QueuedSession> { $0.statusValue == "queued" },
           sort: \QueuedSession.queuePosition)
    private var queue: [QueuedSession]

    @Query(sort: \WorkoutLog.completedAt, order: .reverse)
    private var recentLogs: [WorkoutLog]

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query private var allExercises: [Exercise]

    @State private var showingSession = false
    @State private var navigateToActive = false
    @State private var showingProgramBrowser = false
    @State private var sessionToResume: QueuedSession? = nil

    private var activeProgramType: ProgramType? {
        // Infer the program type from the session template names
        guard let templates = activePrograms.first?.sessionTemplates else { return nil }
        let names = Set(templates.map(\.name))
        if names.contains("Push") { return .pushPullLegs }
        if names.contains("Workout A") { return .stronglifts }
        if names.contains("Chest & Back") { return .arnoldSplit }
        if names.contains("Power Upper") { return .phul }
        if names.contains("Chest") && names.contains("Arms") { return .muscleGroupSplit }
        if names.contains("Full Body A") { return .fullBody }
        return .upperLower
    }

    var nextSession: QueuedSession? { queue.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        headerSection
                        activeProgramRow
                        if !todaysLogs.isEmpty { completedTodaySection }
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
            .sheet(isPresented: $showingProgramBrowser) {
                ProgramBrowserView(currentProgramType: activeProgramType)
            }
            .navigationDestination(isPresented: Binding(
                get: { sessionToResume != nil },
                set: { if !$0 { sessionToResume = nil } }
            )) {
                if let s = sessionToResume {
                    ActiveWorkoutView(session: s, recentLogs: recentLogs)
                }
            }
        }
    }

    // MARK: - Active Program Row

    private var activeProgramRow: some View {
        let def = activeProgramType.map { ProgramLibrary.definition(for: $0) }
        return Button {
            showingProgramBrowser = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: def?.icon ?? "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(def?.name ?? "Program")
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Active program")
                        .font(.ironLogMicro)
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Change")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding(Spacing.sm)
            .ironLogCard()
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

    // MARK: - Completed Today

    private var todaysLogs: [WorkoutLog] {
        recentLogs.filter { Calendar.current.isDateInToday($0.completedAt) }
    }

    @ViewBuilder
    private var completedTodaySection: some View {
        if todaysLogs.count == 1, let log = todaysLogs.first {
            achievementCard(log: log)
        } else {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.orange)
                        .font(.system(size: 13))
                    Text("COMPLETED TODAY (\(todaysLogs.count))")
                        .font(.ironLogMicro)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.orange)
                        .tracking(1.2)
                }
                VStack(spacing: 0) {
                    ForEach(Array(todaysLogs.enumerated()), id: \.element.id) { index, log in
                        if index > 0 { Divider().background(AppTheme.border) }
                        achievementRow(log: log)
                    }
                }
                .ironLogCard()
            }
        }
    }

    private func achievementCard(log: WorkoutLog) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "flame.fill")
                    .foregroundColor(AppTheme.orange)
                    .font(.system(size: 16))
                Text(log.queuedSession?.displayName ?? log.customTitle ?? "Workout")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
            }

            HStack(spacing: Spacing.md) {
                Label("\(log.sets.count) sets", systemImage: "dumbbell.fill")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                Label(volumeString(log), systemImage: "scalemass.fill")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                if let dur = log.durationMinutes {
                    Label("\(dur)m", systemImage: "clock.fill")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Divider().background(AppTheme.border)

            HStack(spacing: Spacing.sm) {
                if let session = log.queuedSession {
                    NavigationLink {
                        SessionCompleteView(
                            log: log,
                            session: session,
                            allExercises: allExercises,
                            priorLogs: recentLogs.filter { $0.id != log.id }
                        )
                    } label: {
                        Text("View Session")
                            .ironLogSecondaryButton()
                    }
                    Button {
                        reopenSession(log: log, session: session)
                    } label: {
                        Text("Reopen")
                            .ironLogPrimaryButton()
                    }
                } else {
                    NavigationLink {
                        SessionHistoryDetailView(log: log, exercises: allExercises)
                    } label: {
                        Text("View Session")
                            .ironLogSecondaryButton()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    private func achievementRow(log: WorkoutLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.queuedSession?.displayName ?? log.customTitle ?? "Workout")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textPrimary)
                HStack(spacing: Spacing.sm) {
                    Text("\(log.sets.count) sets")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("·")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                    Text(volumeString(log))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                    if let dur = log.durationMinutes {
                        Text("·")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text("\(dur)m")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            Spacer()
            if let session = log.queuedSession {
                HStack(spacing: Spacing.xs) {
                    NavigationLink {
                        SessionCompleteView(
                            log: log,
                            session: session,
                            allExercises: allExercises,
                            priorLogs: recentLogs.filter { $0.id != log.id }
                        )
                    } label: {
                        Text("View")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Button {
                        reopenSession(log: log, session: session)
                    } label: {
                        Text("Reopen")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.orange)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(AppTheme.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.md)
    }

    private func volumeString(_ log: WorkoutLog) -> String {
        let vol = log.sets.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        if vol >= 1000 { return String(format: "%.1fk lbs", vol / 1000) }
        return "\(Int(vol)) lbs"
    }

    private func reopenSession(log: WorkoutLog, session: QueuedSession) {
        let entries = session.sessionTemplate?.entries ?? []
        var draftSets: [DraftSet] = []
        for set in log.sets {
            guard let entry = entries.first(where: { $0.exerciseID == set.exerciseID }) else { continue }
            draftSets.append(DraftSet(
                entryID: entry.id.uuidString,
                setNumber: set.setNumber,
                exerciseID: set.exerciseID.uuidString,
                weightLbs: set.weightLbs,
                reps: set.reps,
                targetReps: set.targetReps,
                rpe: set.rpe,
                hitTarget: set.hitTarget
            ))
        }
        let key = DraftSet.draftKey(for: session.id)
        if let data = try? JSONEncoder().encode(draftSets) {
            UserDefaults.standard.set(data, forKey: key)
            let startApprox = log.completedAt.addingTimeInterval(
                -Double((log.durationMinutes ?? 0) * 60)
            )
            UserDefaults.standard.set(startApprox.timeIntervalSince1970, forKey: key + "_start")
        }
        modelContext.delete(log)
        session.status = .queued
        session.workoutLog = nil
        try? modelContext.save()
        sessionToResume = session
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
        NavigationLink {
            DailySessionView(session: session, recentLogs: recentLogs)
        } label: {
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
        .buttonStyle(.plain)
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
        NavigationLink {
            if let session = log.queuedSession {
                SessionCompleteView(
                    log: log,
                    session: session,
                    allExercises: allExercises,
                    priorLogs: recentLogs.filter { $0.id != log.id }
                )
            } else {
                SessionHistoryDetailView(log: log, exercises: allExercises)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.queuedSession?.displayName ?? log.customTitle ?? "Session")
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
        .buttonStyle(.plain)
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
