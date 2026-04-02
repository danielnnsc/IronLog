import SwiftUI
import SwiftData

/// The main workout logging screen. One exercise at a time with set logging,
/// auto-starting rest timer, and navigation between exercises.
struct ActiveWorkoutView: View {

    let session: QueuedSession
    let recentLogs: [WorkoutLog]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @Query private var exercises: [Exercise]

    // MARK: - State

    @State private var currentExerciseIndex = 0
    @State private var loggedSets: [UUID: [SetLog]] = [:]   // entry.id → sets
    @State private var weights: [UUID: Double] = [:]         // entry.id → current weight
    @State private var reps: [UUID: Int] = [:]               // entry.id → current reps
    @State private var rpe: [UUID: Int?] = [:]               // entry.id → current RPE

    // Rest timer — computed from start date so background doesn't affect it
    @State private var restTimer: RestTimerState = .idle
    @State private var restElapsed: Int = 0
    @State private var restTarget: Int = 90
    @State private var restStartDate: Date? = nil
    @State private var restTimer_timer: Timer?

    // Inline edit state — independent of main logger inputs
    @State private var editingSet: (entryID: UUID, index: Int)? = nil
    @State private var editWeight: Double = 0
    @State private var editReps: Int = 0

    // Set timer for time-based exercises (plank, etc.)
    @State private var setTimerElapsed: Int = 0
    @State private var setTimerRunning: Bool = false
    @State private var setTimer_timer: Timer?
    @State private var setTimerStartDate: Date? = nil

    @State private var sessionStartTime = Date.now
    @State private var showingComplete = false
    @State private var completedLog: WorkoutLog?
    @State private var isResuming = false

    @State private var infoExercise: Exercise?
    @State private var showingSwap = false
    @State private var showingAddExercise = false
    @State private var showAbortAlert = false
    @State private var dragOffset: CGFloat = 0
    @State private var navDirection: Int = 1   // 1 = forward, -1 = backward
    @State private var showingExerciseHistory = false

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
                            exerciseHistoryView
                            if !currentSets.isEmpty { loggedSetsView }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                    }
                    .scrollDismissesKeyboard(.interactively)
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
                    if let exercise = currentExercise {
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
            ExerciseInfoSheet(exercise: ex, onSwap: {
                infoExercise = nil
                showingSwap = true
            })
        }
        .sheet(isPresented: $showingSwap) {
            if let entry = currentEntry, let exercise = currentExercise {
                ExerciseSwapView(entry: entry, currentExercise: exercise)
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(session: session, onAdded: {
                currentExerciseIndex = entries.count - 1
            })
        }
        .fullScreenCover(isPresented: $showingComplete, onDismiss: {
            if isResuming {
                isResuming = false
                completedLog = nil
                restoreDraftIfNeeded()
            } else {
                dismiss()
            }
        }) {
            if let log = completedLog {
                SessionCompleteView(
                    log: log,
                    session: session,
                    allExercises: exercises,
                    priorLogs: recentLogs,
                    onResume: { reopenWorkout() }
                )
            }
        }
        .onAppear {
            prepareWeights()
            restoreDraftIfNeeded()
        }
        .onDisappear { stopRestTimer() }
        // Fix: sync rest elapsed when returning from background
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if let start = restStartDate, restTimer != .idle {
                    restElapsed = Int(Date.now.timeIntervalSince(start))
                    if restElapsed >= restTarget { restTimer = .ringing }
                }
                if let start = setTimerStartDate, setTimerRunning {
                    setTimerElapsed = Int(Date.now.timeIntervalSince(start))
                }
            }
        }
        // Haptic when rest timer completes
        .onChange(of: restTimer) { _, newValue in
            if newValue == .ringing {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
        .onChange(of: currentExerciseIndex) { _, _ in
            resetSetTimer()
            showingExerciseHistory = false
        }
    }

    // MARK: - Navigation Strip

    private var navigationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                    let exercise = exercises.first { $0.id == entry.exerciseID }
                    let sets = loggedSets[entry.id] ?? []
                    let done = sets.count >= entry.targetSets

                    Button {
                        navDirection = idx > currentExerciseIndex ? 1 : -1
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            currentExerciseIndex = idx
                        }
                    } label: {
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

                Button { showingAddExercise = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("Add")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
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

            HStack(alignment: .top) {
                Text(currentExercise?.name ?? "")
                    .font(.ironLogDisplay)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button {
                    showingSwap = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Swap")
                    }
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(AppTheme.surface2)
                    .clipShape(Capsule())
                }
            }

            if let entry = currentEntry {
                let repsLabel = entry.targetReps.contains(where: { $0.isLetter })
                    ? entry.targetReps
                    : "\(entry.targetReps) reps"
                Text("\(entry.targetSets) sets · \(repsLabel)")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
            }

            if let notes = currentEntry?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(AppTheme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Exercise History

    private func historySessions(for exerciseID: UUID) -> [(date: Date, sets: [SetLog])] {
        let currentTemplateID = session.sessionTemplate?.id
        return recentLogs
            .filter { log in
                guard let currentTemplateID else {
                    return log.sets.contains { $0.exerciseID == exerciseID }
                }
                return log.queuedSession?.sessionTemplate?.id == currentTemplateID
                    && log.sets.contains { $0.exerciseID == exerciseID }
            }
            .prefix(5)
            .compactMap { log in
                let sets = log.sets
                    .filter { $0.exerciseID == exerciseID }
                    .sorted { $0.setNumber < $1.setNumber }
                return (date: log.completedAt, sets: sets)
            }
    }

    private func ghostSetCard(date: Date, sets: [SetLog]) -> some View {
        let isTimeBased = currentExercise?.isTimeBased == true
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.ironLogMicro)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            ForEach(sets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                        .frame(width: 44, alignment: .leading)

                    Text(isTimeBased
                         ? formatSetTimer(set.reps)
                         : "\(Int(set.weightLbs)) lbs × \(set.reps) reps")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textTertiary)

                    if let rpeVal = set.rpe {
                        Text("· Difficulty \(rpeVal)")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .opacity(0.55)
    }

    private var exerciseHistoryView: some View {
        guard let entry = currentEntry else { return AnyView(EmptyView()) }
        let sessions = historySessions(for: entry.exerciseID)
        guard !sessions.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: Spacing.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingExerciseHistory.toggle()
                    }
                } label: {
                    HStack {
                        Text("LAST SESSION")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
                            .tracking(1.5)
                        Spacer()
                        Image(systemName: showingExerciseHistory ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                }

                if showingExerciseHistory {
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
                            ghostSetCard(date: session.date, sets: session.sets)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        )
    }

    // MARK: - Set Logger

    private var setLogger: some View {
        guard let entry = currentEntry else { return AnyView(EmptyView()) }
        let targetMet = currentSets.count >= entry.targetSets
        let setNumber = currentSets.count + 1
        let entryID = entry.id

        let canLog = currentExercise?.isTimeBased == true
            ? (!setTimerRunning && setTimerElapsed > 0)
            : (reps[entryID] ?? 0) > 0

        return AnyView(
            VStack(spacing: Spacing.md) {
                HStack {
                    Text(targetMet ? "EXTRA SET" : "SET \(setNumber)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                        .tracking(1.5)
                    Spacer()
                }

                // Weight and reps inputs (or set timer for time-based exercises)
                if currentExercise?.isTimeBased == true {
                    setTimerView(entryID: entryID)
                } else {
                    HStack(spacing: Spacing.md) {
                        // Weight
                        VStack(spacing: Spacing.xs) {
                            Text("WEIGHT (lbs)")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)

                            HStack(spacing: Spacing.sm) {
                                Button {
                                    weights[entryID] = max(0, (weights[entryID] ?? 0) - 5)
                                } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 36, height: 36)
                                        .background(AppTheme.surface2)
                                        .clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                TextField("0", value: Binding(
                                    get: { weights[entryID] ?? 0 },
                                    set: { weights[entryID] = max(0, $0) }
                                ), format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 60)

                                Button {
                                    weights[entryID] = (weights[entryID] ?? 0) + 5
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
                }

                // Log Set button — inline, directly under inputs
                if targetMet {
                    HStack(spacing: Spacing.sm) {
                        Text("Target met ✓")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.green)
                        Spacer()
                        Button { logSet() } label: {
                            Text("Add Extra Set")
                                .font(.ironLogCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .disabled(!canLog)
                        .opacity(canLog ? 1 : 0.4)
                    }
                } else {
                    Button { logSet() } label: {
                        Text("Log Set \(setNumber)")
                            .ironLogPrimaryButton()
                    }
                    .disabled(!canLog)
                    .opacity(canLog ? 1 : 0.4)
                }

                rpeSelector(entryID: entryID)
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
                Text("Set Difficulty (optional)")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textTertiary)
                Spacer()
                if let r = rpe[entryID], r != nil {
                    Button { rpe[entryID] = nil } label: {
                        Text("Clear")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }

            HStack(spacing: Spacing.xs) {
                ForEach(1...10, id: \.self) { value in
                    let selected = (rpe[entryID] ?? nil) == value
                    Button { rpe[entryID] = value } label: {
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
                Text("Difficulty \(selectedValue) — \(rpeDefinition(selectedValue))")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.accent)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Logged Sets

    private var loggedSetsView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("LOGGED")
                .font(.ironLogMicro)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            ForEach(Array(currentSets.enumerated()), id: \.element.id) { index, set in
                let isBeingEdited = editingSet?.entryID == currentEntry?.id && editingSet?.index == index

                VStack(spacing: Spacing.xs) {
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                            .frame(width: 44, alignment: .leading)

                        if !isBeingEdited {
                            Text(currentExercise?.isTimeBased == true
                                 ? formatSetTimer(set.reps)
                                 : "\(Int(set.weightLbs)) lbs × \(set.reps) reps")
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)
                            if let rpeVal = set.rpe {
                                Text("Difficulty \(rpeVal)")
                                    .font(.ironLogCaption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Spacer()

                        // Edit button
                        Button {
                            guard let entry = currentEntry else { return }
                            if isBeingEdited {
                                editingSet = nil
                            } else {
                                editWeight = set.weightLbs
                                editReps = set.reps
                                editingSet = (entryID: entry.id, index: index)
                            }
                        } label: {
                            Image(systemName: isBeingEdited ? "xmark.circle" : "pencil.circle")
                                .foregroundColor(isBeingEdited ? AppTheme.textTertiary : AppTheme.textTertiary)
                                .font(.system(size: 18))
                        }

                        // Delete button
                        Button {
                            guard let entry = currentEntry else { return }
                            loggedSets[entry.id]?.remove(at: index)
                            for i in index..<(loggedSets[entry.id]?.count ?? 0) {
                                loggedSets[entry.id]?[i] = SetLog(
                                    exerciseID: loggedSets[entry.id]![i].exerciseID,
                                    setNumber: i + 1,
                                    weightLbs: loggedSets[entry.id]![i].weightLbs,
                                    reps: loggedSets[entry.id]![i].reps,
                                    targetReps: loggedSets[entry.id]![i].targetReps,
                                    rpe: loggedSets[entry.id]![i].rpe,
                                    hitTarget: loggedSets[entry.id]![i].hitTarget,
                                    restDurationSeconds: loggedSets[entry.id]![i].restDurationSeconds
                                )
                            }
                            if editingSet?.index == index { editingSet = nil }
                            saveDraft()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(AppTheme.red)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                        }
                    }

                    // Inline edit controls
                    if isBeingEdited {
                        HStack(spacing: Spacing.sm) {
                            // Weight stepper
                            HStack(spacing: Spacing.xs) {
                                Button { editWeight = max(0, editWeight - 5) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                TextField("0", value: $editWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 64)
                                Button { editWeight += 5 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Divider().frame(height: 24).background(AppTheme.border)

                            // Reps stepper
                            HStack(spacing: Spacing.xs) {
                                Button { editReps = max(0, editReps - 1) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Text("\(editReps) reps")
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 56)
                                Button { editReps += 1 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Spacer()

                            // Save
                            Button { updateSet() } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.green)
                                    .font(.system(size: 26))
                            }
                        }
                        .padding(.leading, 44)
                        .padding(.top, 4)
                    }
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
                        .animation(.linear(duration: 0.5), value: restElapsed)
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

                Button { stopRestTimer() } label: {
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
        resetSetTimer()
        saveDraft()
        startRestTimer(for: exercise)
    }

    private func updateSet() {
        guard let editInfo = editingSet,
              let entry = entries.first(where: { $0.id == editInfo.entryID }),
              editInfo.index < (loggedSets[editInfo.entryID]?.count ?? 0) else {
            editingSet = nil
            return
        }

        let topRep = ProgressionEngine.topRep(from: entry.targetReps)
        let hitTarget = editReps >= topRep
        let existingSet = loggedSets[editInfo.entryID]![editInfo.index]

        loggedSets[editInfo.entryID]![editInfo.index] = SetLog(
            exerciseID: existingSet.exerciseID,
            setNumber: existingSet.setNumber,
            weightLbs: editWeight,
            reps: editReps,
            targetReps: existingSet.targetReps,
            rpe: existingSet.rpe,
            hitTarget: hitTarget,
            restDurationSeconds: existingSet.restDurationSeconds
        )

        editingSet = nil
        saveDraft()
    }

    private func startRestTimer(for exercise: Exercise) {
        stopRestTimer()
        restStartDate = Date.now
        restElapsed = 0
        restTarget = exercise.tier.restRange.upperBound
        restTimer = .running

        NotificationManager.shared.scheduleRestComplete(in: restTarget)

        restTimer_timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let start = restStartDate else { return }
            restElapsed = Int(Date.now.timeIntervalSince(start))
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
        restStartDate = nil
        NotificationManager.shared.cancelRestComplete()
    }

    // MARK: - Set Timer (time-based exercises)

    private func startSetTimer() {
        setTimerStartDate = Date.now
        setTimerElapsed = 0
        setTimerRunning = true
        setTimer_timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let start = setTimerStartDate else { return }
            setTimerElapsed = Int(Date.now.timeIntervalSince(start))
        }
    }

    private func stopSetTimer(entryID: UUID) {
        if let start = setTimerStartDate {
            setTimerElapsed = Int(Date.now.timeIntervalSince(start))
        }
        setTimer_timer?.invalidate()
        setTimer_timer = nil
        setTimerStartDate = nil
        setTimerRunning = false
        reps[entryID] = setTimerElapsed
    }

    private func resetSetTimer() {
        setTimer_timer?.invalidate()
        setTimer_timer = nil
        setTimerStartDate = nil
        setTimerRunning = false
        setTimerElapsed = 0
    }

    private func formatSetTimer(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Set Timer View

    private func setTimerView(entryID: UUID) -> some View {
        VStack(spacing: Spacing.md) {
            Text(formatSetTimer(setTimerElapsed))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundColor(setTimerRunning ? AppTheme.accent : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            Button {
                if setTimerRunning {
                    stopSetTimer(entryID: entryID)
                } else {
                    startSetTimer()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: setTimerRunning ? "stop.fill" : "play.fill")
                    Text(setTimerRunning ? "Stop" : (setTimerElapsed > 0 ? "Restart" : "Start"))
                }
                .font(.ironLogHeadline)
                .foregroundColor(setTimerRunning ? AppTheme.red : AppTheme.green)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background((setTimerRunning ? AppTheme.red : AppTheme.green).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    private func finishWorkout() {
        stopRestTimer()

        let allSets = loggedSets.values.flatMap { $0 }
        guard !allSets.isEmpty else {
            clearDraft()
            dismiss()
            return
        }

        let duration = Int(Date.now.timeIntervalSince(sessionStartTime) / 60)

        // Insert parent first (empty sets), then insert and attach each set.
        // SwiftData requires the owner to be tracked before children are assigned.
        let workoutLog = WorkoutLog(
            completedAt: .now,
            durationMinutes: duration,
            sets: [],
            queuedSession: session
        )
        modelContext.insert(workoutLog)

        for set in allSets {
            modelContext.insert(set)
            workoutLog.sets.append(set)
        }

        session.status = .completed
        session.workoutLog = workoutLog

        // Remove any exercises that were added just for this session
        let sessionOnlyKey = "sessionOnly_\(session.id.uuidString)"
        let sessionOnlyIDs = (UserDefaults.standard.stringArray(forKey: sessionOnlyKey) ?? [])
            .compactMap { UUID(uuidString: $0) }
        if !sessionOnlyIDs.isEmpty, let template = session.sessionTemplate {
            let toRemove = template.entries.filter { sessionOnlyIDs.contains($0.id) }
            for entry in toRemove {
                template.entries.removeAll { $0.id == entry.id }
                modelContext.delete(entry)
            }
            UserDefaults.standard.removeObject(forKey: sessionOnlyKey)
        }

        try? modelContext.save()
        clearDraft()

        let workoutStart = sessionStartTime
        let storedWeightLbs = Double(UserDefaults.standard.integer(forKey: "userWeightLbs"))
        Task {
            let hkWeight = await HealthKitManager.shared.fetchBodyMassLbs()
            let bodyWeight = hkWeight ?? (storedWeightLbs > 0 ? storedWeightLbs : 175.0)
            await HealthKitManager.shared.saveWorkout(
                startDate: workoutStart,
                durationMinutes: duration,
                bodyWeightLbs: bodyWeight
            )
        }

        completedLog = workoutLog
        showingComplete = true
    }

    // MARK: - Reopen

    private func reopenWorkout() {
        guard let log = completedLog else { return }
        let entries = session.sessionTemplate?.entries ?? []

        // Reconstruct the draft from the completed WorkoutLog's sets,
        // mapping exerciseID → entryID via the session template
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
        if let data = try? JSONEncoder().encode(draftSets) {
            UserDefaults.standard.set(data, forKey: draftKey)
            UserDefaults.standard.set(log.completedAt.timeIntervalSince1970, forKey: draftKey + "_start")
        }

        // Revert SwiftData state
        modelContext.delete(log)
        session.status = .queued
        session.workoutLog = nil
        try? modelContext.save()

        isResuming = true
        showingComplete = false
    }

    // MARK: - Draft Autosave

    private var draftKey: String { DraftSet.draftKey(for: session.id) }

    private func saveDraft() {
        var draftSets: [DraftSet] = []
        for (entryID, sets) in loggedSets {
            for set in sets {
                draftSets.append(DraftSet(
                    entryID: entryID.uuidString,
                    setNumber: set.setNumber,
                    exerciseID: set.exerciseID.uuidString,
                    weightLbs: set.weightLbs,
                    reps: set.reps,
                    targetReps: set.targetReps,
                    rpe: set.rpe,
                    hitTarget: set.hitTarget
                ))
            }
        }
        if let data = try? JSONEncoder().encode(draftSets) {
            UserDefaults.standard.set(data, forKey: draftKey)
            UserDefaults.standard.set(sessionStartTime.timeIntervalSince1970, forKey: draftKey + "_start")
        }
    }

    private func restoreDraftIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draftSets = try? JSONDecoder().decode([DraftSet].self, from: data) else { return }

        if let startInterval = UserDefaults.standard.object(forKey: draftKey + "_start") as? Double {
            sessionStartTime = Date(timeIntervalSince1970: startInterval)
        }

        var restored: [UUID: [SetLog]] = [:]
        for draft in draftSets {
            guard let entryID = UUID(uuidString: draft.entryID),
                  let exerciseID = UUID(uuidString: draft.exerciseID) else { continue }
            let set = SetLog(
                exerciseID: exerciseID,
                setNumber: draft.setNumber,
                weightLbs: draft.weightLbs,
                reps: draft.reps,
                targetReps: draft.targetReps,
                rpe: draft.rpe,
                hitTarget: draft.hitTarget,
                restDurationSeconds: nil
            )
            restored[entryID, default: []].append(set)
        }
        if !restored.isEmpty {
            loggedSets = restored
        }
    }

    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
        UserDefaults.standard.removeObject(forKey: draftKey + "_start")
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

struct DraftSet: Codable {
    let entryID: String
    let setNumber: Int
    let exerciseID: String
    let weightLbs: Double
    let reps: Int
    let targetReps: String
    let rpe: Int?
    let hitTarget: Bool

    static func draftKey(for sessionID: UUID) -> String {
        "workoutDraft_\(sessionID.uuidString)"
    }
}
