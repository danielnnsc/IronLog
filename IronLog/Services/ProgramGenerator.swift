import SwiftData
import Foundation

/// Generates a new Program with SessionTemplates and a rolling queue of QueuedSessions.
struct ProgramGenerator {

    let modelContext: ModelContext
    let scheduledDays: [Weekday]
    let weeksToGenerate: Int
    var programType: ProgramType = .upperLower

    // MARK: - Entry Point

    /// Creates, inserts, and saves a new active Program.
    @MainActor
    func generate() throws -> Program {
        // Deactivate any existing active program
        let existingDescriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
        let existing = try modelContext.fetch(existingDescriptor)
        for p in existing { p.isActive = false }

        let templates = buildTemplates(for: programType)
        for t in templates { modelContext.insert(t) }

        let program = Program(scheduledDays: scheduledDays, sessionTemplates: templates)
        modelContext.insert(program)

        let sessions = buildQueue(templates: templates)
        for s in sessions { modelContext.insert(s) }

        try modelContext.save()
        return program
    }

    // MARK: - Switch Program (preserves WorkoutLog history)

    /// Replaces the current program and queue with a new program type.
    /// All completed WorkoutLog records are preserved.
    @MainActor
    static func switchProgram(
        to type: ProgramType,
        scheduledDays: [Weekday],
        weeksToGenerate: Int = 8,
        context: ModelContext
    ) throws {
        // Delete only queued (not completed/skipped) sessions
        let queuedDescriptor = FetchDescriptor<QueuedSession>(
            predicate: #Predicate { $0.statusValue == "queued" }
        )
        let queuedSessions = try context.fetch(queuedDescriptor)
        for s in queuedSessions { context.delete(s) }

        // Generate the new program
        let generator = ProgramGenerator(
            modelContext: context,
            scheduledDays: scheduledDays,
            weeksToGenerate: weeksToGenerate,
            programType: type
        )
        _ = try generator.generate()
    }

    // MARK: - Add a Single Session to the Queue

    /// Builds one session template from another program type and appends it to the end of the queue.
    @MainActor
    static func addSession(
        named sessionName: String,
        from type: ProgramType,
        context: ModelContext,
        scheduledDays: [Weekday]
    ) throws {
        let generator = ProgramGenerator(
            modelContext: context,
            scheduledDays: scheduledDays,
            weeksToGenerate: 1,
            programType: type
        )
        let allTemplates = generator.buildTemplates(for: type)
        guard let template = allTemplates.first(where: { $0.name == sessionName }) ?? allTemplates.first else { return }

        // Attach the template to the active program
        let activeDescriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
        if let activeProgram = try context.fetch(activeDescriptor).first {
            context.insert(template)
            activeProgram.sessionTemplates.append(template)
        } else {
            context.insert(template)
        }

        // Find the current max queue position and designated date
        let queueDescriptor = FetchDescriptor<QueuedSession>(
            predicate: #Predicate { $0.statusValue == "queued" },
            sortBy: [SortDescriptor(\.queuePosition, order: .reverse)]
        )
        let existingSessions = try context.fetch(queueDescriptor)
        let maxPosition = existingSessions.first?.queuePosition ?? 0
        let lastDate = existingSessions.first?.designatedDate

        // Assign the next scheduled date after the last queued session
        let nextDate: Date?
        if let lastDate {
            nextDate = nextNScheduledDates(from: lastDate, scheduledDays: scheduledDays, count: 1).first
        } else {
            nextDate = nextNScheduledDates(from: .now, scheduledDays: scheduledDays, count: 1).first
        }

        let session = QueuedSession(
            queuePosition: maxPosition + 1,
            designatedDate: nextDate,
            sessionNumber: 1,
            sessionTemplate: template
        )
        context.insert(session)
        try context.save()
    }

    // MARK: - Template Dispatcher

    func buildTemplates(for type: ProgramType) -> [SessionTemplate] {
        switch type {
        case .upperLower:      return buildUpperLowerTemplates()
        case .pushPullLegs:    return buildPPLTemplates()
        case .fullBody:        return buildFullBodyTemplates()
        case .muscleGroupSplit: return buildMuscleGroupSplitTemplates()
        case .stronglifts:     return buildStrongliftsTemplates()
        case .arnoldSplit:     return buildArnoldSplitTemplates()
        case .phul:            return buildPHULTemplates()
        }
    }

    // MARK: - Upper / Lower (existing)

    private func buildUpperLowerTemplates() -> [SessionTemplate] {
        [buildUpperA(), buildLowerA(), buildUpperB(), buildLowerB()]
    }

    private func buildUpperA() -> SessionTemplate {
        let t = SessionTemplate(name: "Upper A", order: 1)
        t.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – focus on controlled descent", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.tricepPushdownID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.bicepCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 4),
        ]
        return t
    }

    private func buildLowerA() -> SessionTemplate {
        let t = SessionTemplate(name: "Lower A", order: 2)
        t.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – hit full depth", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.legPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 3, targetReps: "8-10",
                          notes: "Focus on hamstring stretch", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 4),
        ]
        return t
    }

    private func buildUpperB() -> SessionTemplate {
        let t = SessionTemplate(name: "Upper B", order: 3)
        t.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – strict form, no leg drive", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.pullUpsID,
                          targetSets: 3, targetReps: "6-10",
                          notes: "Full dead hang each rep", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableRowID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.facePullID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 4),
        ]
        return t
    }

    private func buildLowerB() -> SessionTemplate {
        let t = SessionTemplate(name: "Lower B", order: 4)
        t.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – heavier than Lower A secondary slot", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.bulgarianSSID,
                          targetSets: 3, targetReps: "10-12",
                          notes: "Each leg – use dumbbell", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legExtensionID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.hipThrustID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.walkingLungesID,
                          targetSets: 3, targetReps: "12-15",
                          notes: "Each leg counts as one rep", sortOrder: 4),
        ]
        return t
    }

    // MARK: - Push / Pull / Legs

    private func buildPPLTemplates() -> [SessionTemplate] {
        let push = SessionTemplate(name: "Push", order: 1)
        push.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – chest focus", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.tricepPushdownID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.ohTricepExtID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 5),
        ]

        let pull = SessionTemplate(name: "Pull", order: 2)
        pull.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – back thickness", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.pullUpsID,
                          targetSets: 3, targetReps: "6-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableRowID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.facePullID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.bicepCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.hammerCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 5),
        ]

        let legs = SessionTemplate(name: "Legs", order: 3)
        legs.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – hit full depth", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 4),
        ]

        return [push, pull, legs]
    }

    // MARK: - Full Body

    private func buildFullBodyTemplates() -> [SessionTemplate] {
        let a = SessionTemplate(name: "Full Body A", order: 1)
        a.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "5-6",
                          notes: "Anchor – primary lower", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 3, targetReps: "6-8", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 3, targetReps: "6-8", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 3),
        ]

        let b = SessionTemplate(name: "Full Body B", order: 2)
        b.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – primary hinge", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 3, targetReps: "6-8", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.pullUpsID,
                          targetSets: 3, targetReps: "6-10", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.hipThrustID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
        ]

        let c = SessionTemplate(name: "Full Body C", order: 3)
        c.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.gobletSquatID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableRowID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 4),
        ]

        return [a, b, c]
    }

    // MARK: - Muscle Group Split

    private func buildMuscleGroupSplitTemplates() -> [SessionTemplate] {
        let chest = SessionTemplate(name: "Chest", order: 1)
        chest.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – primary chest", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 4, targetReps: "10-12", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableChestFlyeID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.dipsID,
                          targetSets: 3, targetReps: "8-12", sortOrder: 3),
        ]

        let back = SessionTemplate(name: "Back", order: 2)
        back.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – back thickness", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.pullUpsID,
                          targetSets: 3, targetReps: "6-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableRowID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.facePullID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 3),
        ]

        let shoulders = SessionTemplate(name: "Shoulders", order: 3)
        shoulders.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – press strength", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.dbShoulderPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.facePullID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 3),
        ]

        let arms = SessionTemplate(name: "Arms", order: 4)
        arms.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.bicepCurlID,
                          targetSets: 4, targetReps: "10-12", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.tricepPushdownID,
                          targetSets: 4, targetReps: "10-12", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.hammerCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.ohTricepExtID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.preacherCurlID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 4),
        ]

        let legs = SessionTemplate(name: "Legs", order: 5)
        legs.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – primary quad", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 4),
        ]

        return [chest, back, shoulders, arms, legs]
    }

    // MARK: - Stronglifts 5×5

    private func buildStrongliftsTemplates() -> [SessionTemplate] {
        let a = SessionTemplate(name: "Workout A", order: 1)
        a.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 5, targetReps: "5",
                          notes: "Add 5 lbs every session", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 5, targetReps: "5",
                          notes: "Add 5 lbs every session", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 5, targetReps: "5",
                          notes: "Add 5 lbs every session", sortOrder: 2),
        ]

        let b = SessionTemplate(name: "Workout B", order: 2)
        b.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 5, targetReps: "5",
                          notes: "Add 5 lbs every session", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 5, targetReps: "5",
                          notes: "Add 5 lbs every session", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.conventionalDLID,
                          targetSets: 1, targetReps: "5",
                          notes: "Add 10 lbs every session", sortOrder: 2),
        ]

        return [a, b]
    }

    // MARK: - Arnold Split

    private func buildArnoldSplitTemplates() -> [SessionTemplate] {
        let chestBack = SessionTemplate(name: "Chest & Back", order: 1)
        chestBack.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – heavy chest", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Superset with bench if possible", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.pullUpsID,
                          targetSets: 3, targetReps: "6-10", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.dbPulloverID,
                          targetSets: 3, targetReps: "12-15",
                          notes: "Expands the rib cage", sortOrder: 4),
        ]

        let shouldersArms = SessionTemplate(name: "Shoulders & Arms", order: 2)
        shouldersArms.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.arnoldPressID,
                          targetSets: 4, targetReps: "8-10",
                          notes: "Anchor – all 3 delt heads", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.bicepCurlID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.tricepPushdownID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.hammerCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.ohTricepExtID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 5),
        ]

        let legs = SessionTemplate(name: "Legs", order: 3)
        legs.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "6-8",
                          notes: "Anchor – full depth", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legPressID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.walkingLungesID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 5),
        ]

        return [chestBack, shouldersArms, legs]
    }

    // MARK: - PHUL

    private func buildPHULTemplates() -> [SessionTemplate] {
        let powerUpper = SessionTemplate(name: "Power Upper", order: 1)
        powerUpper.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.benchPressID,
                          targetSets: 4, targetReps: "3-5",
                          notes: "Anchor – max strength", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.barbellRowID,
                          targetSets: 4, targetReps: "3-5", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.ohpID,
                          targetSets: 3, targetReps: "5-8", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.closeGripBenchID,
                          targetSets: 3, targetReps: "5-8", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.bicepCurlID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 4),
        ]

        let powerLower = SessionTemplate(name: "Power Lower", order: 2)
        powerLower.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.backSquatID,
                          targetSets: 4, targetReps: "3-5",
                          notes: "Anchor – max strength", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.conventionalDLID,
                          targetSets: 4, targetReps: "3-5", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legPressID,
                          targetSets: 3, targetReps: "6-8", sortOrder: 2),
        ]

        let hypUpper = SessionTemplate(name: "Hypertrophy Upper", order: 3)
        hypUpper.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.inclineDBPressID,
                          targetSets: 4, targetReps: "8-12", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.cableRowID,
                          targetSets: 4, targetReps: "8-12", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.cableChestFlyeID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.lateralRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.hammerCurlID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.tricepPushdownID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 5),
            TemplateEntry(exerciseID: ExerciseLibrary.facePullID,
                          targetSets: 3, targetReps: "15-20", sortOrder: 6),
        ]

        let hypLower = SessionTemplate(name: "Hypertrophy Lower", order: 4)
        hypLower.entries = [
            TemplateEntry(exerciseID: ExerciseLibrary.hackSquatID,
                          targetSets: 4, targetReps: "8-12", sortOrder: 0),
            TemplateEntry(exerciseID: ExerciseLibrary.romanianDLID,
                          targetSets: 3, targetReps: "8-10", sortOrder: 1),
            TemplateEntry(exerciseID: ExerciseLibrary.legCurlID,
                          targetSets: 3, targetReps: "10-12", sortOrder: 2),
            TemplateEntry(exerciseID: ExerciseLibrary.legExtensionID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 3),
            TemplateEntry(exerciseID: ExerciseLibrary.hipThrustID,
                          targetSets: 3, targetReps: "12-15", sortOrder: 4),
            TemplateEntry(exerciseID: ExerciseLibrary.calfRaiseID,
                          targetSets: 4, targetReps: "15-20", sortOrder: 5),
        ]

        return [powerUpper, powerLower, hypUpper, hypLower]
    }

    // MARK: - Queue Generation

    private func buildQueue(templates: [SessionTemplate]) -> [QueuedSession] {
        let sortedTemplates = templates.sorted { $0.order < $1.order }
        let dates = upcomingScheduledDates()
        var sessionCountPerTemplate: [UUID: Int] = [:]
        var sessions: [QueuedSession] = []

        for (index, date) in dates.enumerated() {
            let template = sortedTemplates[index % sortedTemplates.count]
            let sessionNumber = (sessionCountPerTemplate[template.id] ?? 0) + 1
            sessionCountPerTemplate[template.id] = sessionNumber

            let session = QueuedSession(
                queuePosition: index + 1,
                designatedDate: date,
                sessionNumber: sessionNumber,
                sessionTemplate: template
            )
            sessions.append(session)
        }
        return sessions
    }

    private func upcomingScheduledDates() -> [Date] {
        let calendar = Calendar.current
        let targetCount = weeksToGenerate * scheduledDays.count
        var dates: [Date] = []
        var cursor = calendar.startOfDay(for: .now)

        while dates.count < targetCount {
            let rawWeekday = calendar.component(.weekday, from: cursor) - 1
            if let day = Weekday(rawValue: rawWeekday), scheduledDays.contains(day) {
                dates.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return dates
    }

    // MARK: - Deload Insertion

    @MainActor
    static func insertDeload(
        for template: SessionTemplate,
        in context: ModelContext,
        scheduledDays: [Weekday]
    ) throws {
        let descriptor = FetchDescriptor<QueuedSession>(
            predicate: #Predicate { $0.statusValue == "queued" },
            sortBy: [SortDescriptor(\.queuePosition)]
        )
        let existingSessions = try context.fetch(descriptor)

        for s in existingSessions {
            s.queuePosition += 4
            if let date = s.designatedDate {
                s.designatedDate = nextScheduledDate(after: date, scheduledDays: scheduledDays, shift: 4)
            }
        }

        let deloadDates = nextNScheduledDates(from: .now, scheduledDays: scheduledDays, count: 4)

        for (i, date) in deloadDates.enumerated() {
            let deload = QueuedSession(
                queuePosition: i + 1,
                designatedDate: date,
                isDeload: true,
                sessionNumber: 0,
                sessionTemplate: template
            )
            context.insert(deload)
        }

        try context.save()
    }

    private static func nextScheduledDate(after date: Date, scheduledDays: [Weekday], shift: Int) -> Date {
        let dates = nextNScheduledDates(from: date, scheduledDays: scheduledDays, count: shift + 1)
        return dates.last ?? date
    }

    static func nextNScheduledDates(from start: Date, scheduledDays: [Weekday], count: Int) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var cursor = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start)) ?? start

        while dates.count < count {
            let rawWeekday = calendar.component(.weekday, from: cursor) - 1
            if let day = Weekday(rawValue: rawWeekday), scheduledDays.contains(day) {
                dates.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return dates
    }
}
