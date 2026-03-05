import SwiftUI
import SwiftData

/// The main workout logging screen. One exercise at a time with set logging,
/// auto-starting rest timer, and navigation between exercises.
struct ActiveWorkoutView: View {

    let session: QueuedSession
    let recentLogs: [WorkoutLog]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var exercises: [Exercise]

    // MARK: - State

    @State private var currentExerciseIndex = 0
    @State private var loggedSets: [UUID: [SetLog]] = [:]   // entry.id → sets
    @State private var weights: [UUID: Double] = [:]         // entry.id → current weight
    @State private var reps: [UUID: Int] = [:]               // entry.id → current reps
    @State private var rpe: [UUID: Int?] = [:]               // entry.id → current RPE

    @State private var restTimer: RestTimerState = .idle
    @State private var restElapsed: Int = 0
    @State private var restTarget: Int = 90
    @State private var restTimer_timer: Timer?

    @State private var sessionStartTime = Date.now
    @State private var showingComplete = false
    @State private var completedLog: WorkoutLog?

    @State private var infoExercise: Exercise?
    @State private var swapEntry: TemplateEntry?
    @State private var showAbortAlert = false
    @State private var dragOffset: CGFloat = 0
    @State private var navDirection: Int = 1   // 1 = forward, -1 = backward

    // MARK: - Computed

    private var entries: [TemplateEntry] {
        session.sessionTemplate?.sortedEntries ?? []
    }

    private var currentEntry: TemplateEntry? {
        guard currentExerciseIndex < entries.count else { return nil }
        return entries[currentExerciseIndex]
    }

    private var currentExercise: Exercise? {
        guard let entry = currentEntry else { return nil }
        return exercises.first { $0.id == entry.exerciseID }
    }

    private var currentSets: [SetLog] {
        guard let entry = currentEntry else { return [] }
        return loggedSets[entry.id] ?? []
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationStrip
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)

                Divider().background(AppTheme.border)

                ZStack {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            exerciseHeader
                            setLogger
                            if !currentSets.isEmpty { loggedSetsView }
                            Spacer(minLength: Spacing.xxl)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                    }
                    .id(currentExerciseIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: navDirection >= 0 ? .trailing : .leading),
                        removal:   .move(edge: navDirection >= 0 ? .leading  : .trailing)
                    ))
                }
                .offset(x: dragOffset)
                .clipped()
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            let atStart = currentExerciseIndex == 0 && value.translation.width > 0
                            let atEnd = currentExerciseIndex == entries.count - 1 && value.translation.width < 0
                            dragOffset = (atStart || atEnd)
                                ? value.translation.width * 0.15
                                : value.translation.width * 0.45
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else {
                                withAnimation(.spring()) { dragOffset = 0 }
                                return
                            }
                            let threshold: CGFloat = 60
                            if value.translation.width < -threshold, currentExerciseIndex < entries.count - 1 {
                                navDirection = 1
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentExerciseIndex += 1
                                    dragOffset = 0
                                }
                            } else if value.translation.width > threshold, currentExerciseIndex > 0 {
                                navDirection = -1
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentExerciseIndex -= 1
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring()) { dragOffset = 0 }
                            }
                        }
                )

                if restTimer != .idle {
                    restTimerBar
                }

                bottomBar
            }
        }
        .navigationTitle(session.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showAbortAlert = true } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let entry = currentEntry, let exercise = currentExercise {
                        infoExercise = exercise
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .alert("End Workout?", isPresented: $showAbortAlert) {
            Button("End & Save", role: .destructive) { finishWorkout() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your logged sets will be saved.")
        }
        .sheet(item: $infoExercise) { ex in
            ExerciseInfoSheet(exercise: ex, onSwap: { infoExercise = nil })
        }
        .fullScreenCover(isPresented: $showingComplete) {
            if let log = completedLog {
                SessionCompleteView(
                    log: log,
                    session: session,
                    allExercises: exercises,
                    priorLogs: recentLogs
                )
            }
        }
        .onAppear { prepareWeights() }
        .onDisappear { stopRestTimer() }
    }

    // MARK: - Navigation Strip

    private var navigationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                    let exercise = exercises.first { $0.id == entry.exerciseID }
                    let sets = loggedSets[entry.id] ?? []
                    let done = sets.count >= entry.targetSets

                    Button { currentExerciseIndex = idx } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(done ? AppTheme.green : (idx == currentExerciseIndex ? AppTheme.accent : AppTheme.surface3))
                                .frame(width: 10, height: 10)
                            Text(abbreviate(exercise?.name ?? "Ex"))
                                .font(.ironLogMicro)
                                .foregroundColor(idx == currentExerciseIndex ? AppTheme.accent : AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let tier = currentExercise?.tier {
                Text(tier.displayName.uppercased())
                    .font(.ironLogMicro)
                    .foregroundColor(tierColor(tier))
                    .tracking(1.5)
            }

            Text(currentExercise?.name ?? "")
                .font(.ironLogDisplay)
                .foregroundColor(AppTheme.textPrimary)

            if let entry = currentEntry {
                Text("\(entry.targetSets) sets · \(entry.targetReps) reps")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Set Logger

    private var setLogger: some View {
        guard let entry = currentEntry else { return AnyView(EmptyView()) }
        let setNumber = currentSets.count + 1
        let isDone = currentSets.count >= entry.targetSets
        let entryID = entry.id

        return AnyView(
            VStack(spacing: Spacing.md) {
                if !isDone {
                    Text("SET \(setNumber)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                        .tracking(1.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Weight and reps inputs
                HStack(spacing: Spacing.md) {
                    // Weight
                    VStack(spacing: Spacing.xs) {
                        Text("WEIGHT (lbs)")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
                            .tracking(1)

                        HStack(spacing: Spacing.sm) {
                            Button {
                                let step: Double = 5
                                weights[entryID] = max(0, (weights[entryID] ?? 0) - step)
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface2)
                                    .clipShape(Circle())
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Text(String(format: "%.0f", weights[entryID] ?? 0))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(minWidth: 60)

                            Button {
                                let step: Double = 5
                                weights[entryID] = (weights[entryID] ?? 0) + step
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface2)
                                    .clipShape(Circle())
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                    // Reps
                    VStack(spacing: Spacing.xs) {
                        Text("REPS")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
                            .tracking(1)

                        HStack(spacing: Spacing.sm) {
                            Button {
                                reps[entryID] = max(0, (reps[entryID] ?? 0) - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface2)
                                    .clipShape(Circle())
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Text("\(reps[entryID] ?? 0)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(minWidth: 40)

                            Button {
                                reps[entryID] = (reps[entryID] ?? 0) + 1
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface2)
                                    .clipShape(Circle())
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }

                // RPE (optional)
                rpeSelector(entryID: entryID)

                // Log Set button
                if !isDone {
                    Button { logSet() } label: {
                        Text("Log Set \(setNumber)")
                            .ironLogPrimaryButton()
                    }
                    .disabled((reps[entryID] ?? 0) == 0)
                    .opacity((reps[entryID] ?? 0) == 0 ? 0.4 : 1)
                } else {
                    Text("All \(entry.targetSets) sets complete")
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.md)
                }
            }
        )
    }

    // MARK: - RPE Selector

    private func rpeDefinition(_ value: Int) -> String {
        switch value {
        case 1:  return "Very light — minimal effort"
        case 2:  return "Light — easy, could go much longer"
        case 3:  return "Moderate light — comfortable pace"
        case 4:  return "Moderate — starting to feel it"
        case 5:  return "Moderate hard — challenging but manageable"
        case 6:  return "Hard — ~4 reps left in the tank"
        case 7:  return "Hard — ~3 reps left in the tank"
        case 8:  return "Very hard — ~2 reps left in the tank"
        case 9:  return "Near-maximal — 1 rep left in the tank"
        case 10: return "All-out — nothing left, true max effort"
        default: return ""
        }
    }

    private func rpeSelector(entryID: UUID) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("RPE (optional)")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textTertiary)
                Spacer()
                if let r = rpe[entryID], r != nil {
                    Button {
                        rpe[entryID] = nil
                    } label: {
                        Text("Clear")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }

            HStack(spacing: Spacing.xs) {
                ForEach(1...10, id: \.self) { value in
                    let selected = (rpe[entryID] ?? nil) == value
                    Button {
                        rpe[entryID] = value
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 13, weight: selected ? .bold : .regular))
                            .foregroundColor(selected ? .black : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(selected ? AppTheme.accent : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    }
                }
            }

            if let r = rpe[entryID], let selectedValue = r {
                Text("RPE \(selectedValue) — \(rpeDefinition(selectedValue))")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.accent)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Logged Sets

    private var loggedSetsView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Logged")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1)

            ForEach(currentSets, id: \.id) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                        .frame(width: 44, alignment: .leading)

                    Text("\(Int(set.weightLbs)) lbs")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("×")
                        .foregroundColor(AppTheme.textTertiary)

                    Text("\(set.reps) reps")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)

                    if let rpeVal = set.rpe {
                        Text("RPE \(rpeVal)")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: set.hitTarget ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(set.hitTarget ? AppTheme.green : AppTheme.textTertiary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Rest Timer Bar

    private var restTimerBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    AppTheme.surface2
                    let progress = min(1.0, Double(restElapsed) / Double(restTarget))
                    (restTimer == .ringing ? AppTheme.orange : AppTheme.accent)
                        .frame(width: geo.size.width * progress)
                        .animation(.linear(duration: 1), value: restElapsed)
                }
            }
            .frame(height: 4)

            HStack {
                Image(systemName: "timer")
                    .foregroundColor(AppTheme.textSecondary)
                    .font(.ironLogCaption)

                Text(formatRest(restElapsed))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(restTimer == .ringing ? AppTheme.orange : AppTheme.textSecondary)

                Text("/ \(formatRest(restTarget))")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textTertiary)

                Spacer()

                Button {
                    stopRestTimer()
                } label: {
                    Text("Skip Rest")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(AppTheme.background)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                if currentExerciseIndex > 0 {
                    navDirection = -1
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        currentExerciseIndex -= 1
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 48, height: 48)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .foregroundColor(currentExerciseIndex == 0 ? AppTheme.textTertiary : AppTheme.textPrimary)
            }
            .disabled(currentExerciseIndex == 0)

            Button {
                if currentExerciseIndex < entries.count - 1 {
                    navDirection = 1
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        currentExerciseIndex += 1
                    }
                } else {
                    finishWorkout()
                }
            } label: {
                HStack {
                    Text(currentExerciseIndex < entries.count - 1 ? "Next Exercise" : "Finish Workout")
                    Image(systemName: currentExerciseIndex < entries.count - 1 ? "chevron.right" : "checkmark")
                }
                .ironLogPrimaryButton()
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(AppTheme.background)
    }

    // MARK: - Actions

    private func prepareWeights() {
        for entry in entries {
            guard let exercise = exercises.first(where: { $0.id == entry.exerciseID }) else { continue }
            let weight = ProgressionEngine.recommendedWeight(
                for: exercise.id,
                nextSessionNumber: session.sessionNumber,
                exercise: exercise,
                priorLogs: recentLogs
            ) ?? exercise.suggestedStartWeightLbs ?? 0

            let finalWeight: Double
            if session.isDeload {
                finalWeight = ProgressionEngine.deloadWeight(for: exercise.id, priorLogs: recentLogs) ?? weight * 0.5
            } else {
                finalWeight = weight
            }

            weights[entry.id] = finalWeight
            reps[entry.id] = ProgressionEngine.bottomRep(from: entry.targetReps)
        }
    }

    private func logSet() {
        guard let entry = currentEntry,
              let exercise = currentExercise else { return }

        let w = weights[entry.id] ?? 0
        let r = reps[entry.id] ?? 0
        let rpeVal = rpe[entry.id] ?? nil
        let existingSets = loggedSets[entry.id] ?? []
        let setNumber = existingSets.count + 1
        let topRep = ProgressionEngine.topRep(from: entry.targetReps)
        let hitTarget = r >= topRep

        let lastRestStart = existingSets.last.flatMap { _ in Date.now } // simplified
        let restSeconds = restTimer == .idle ? nil : restElapsed

        let set = SetLog(
            exerciseID: exercise.id,
            setNumber: setNumber,
            weightLbs: w,
            reps: r,
            targetReps: entry.targetReps,
            rpe: rpeVal,
            hitTarget: hitTarget,
            restDurationSeconds: restSeconds
        )

        loggedSets[entry.id, default: []].append(set)

        // Start rest timer
        startRestTimer(for: exercise)
    }

    private func startRestTimer(for exercise: Exercise) {
        stopRestTimer()
        restElapsed = 0
        restTarget = exercise.tier.restRange.upperBound
        restTimer = .running

        restTimer_timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            restElapsed += 1
            if restElapsed >= restTarget {
                restTimer = .ringing
            }
        }
    }

    private func stopRestTimer() {
        restTimer_timer?.invalidate()
        restTimer_timer = nil
        restTimer = .idle
        restElapsed = 0
    }

    private func finishWorkout() {
        stopRestTimer()

        let allSets = loggedSets.values.flatMap { $0 }
        guard !allSets.isEmpty else {
            dismiss()
            return
        }

        let duration = Int(Date.now.timeIntervalSince(sessionStartTime) / 60)
        let workoutLog = WorkoutLog(
            completedAt: .now,
            durationMinutes: duration,
            sets: allSets,
            queuedSession: session
        )

        modelContext.insert(workoutLog)
        for set in allSets { modelContext.insert(set) }

        session.status = .completed
        session.workoutLog = workoutLog

        try? modelContext.save()

        completedLog = workoutLog
        showingComplete = true
    }

    // MARK: - Helpers

    private func abbreviate(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count == 1 { return String(name.prefix(4)) }
        return words.prefix(2).map { String($0.prefix(1)) }.joined()
    }

    private func formatRest(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func tierColor(_ tier: ExerciseTier) -> Color {
        switch tier {
        case .anchor:    return AppTheme.accent
        case .secondary: return AppTheme.blue
        case .accessory: return AppTheme.textTertiary
        }
    }
}

// MARK: - Supporting Types

enum RestTimerState {
    case idle, running, ringing
}
