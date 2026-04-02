#if DEBUG
import SwiftData
import Foundation

/// Populates the store with a realistic program + workout history for development.
/// Triggered by passing `-devSeed` as a launch argument in the Xcode scheme.
/// Wipes all existing data first so the result is always clean and reproducible.
@MainActor
struct DevSeeder {

    static func seed(in context: ModelContext) throws {
        try wipeAll(in: context)

        // Seed exercises first (DevSeeder wipes them too)
        try DataSeeder.seedExercisesIfNeeded(in: context)

        // Generate a Mon/Wed/Fri upper-lower program
        let generator = ProgramGenerator(
            modelContext: context,
            scheduledDays: [.monday, .wednesday, .friday],
            weeksToGenerate: 8,
            programType: .upperLower
        )
        let program = try generator.generate()

        // Fetch the templates so we can look up exercise IDs for history
        let upperTemplates = program.sessionTemplates.filter { $0.name.contains("Upper") }.sorted { $0.order < $1.order }
        let lowerTemplates = program.sessionTemplates.filter { $0.name.contains("Lower") }.sorted { $0.order < $1.order }

        // Build 6 weeks of completed workout logs (Mon/Wed/Fri, ending yesterday)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        // Dates: 6 weeks back, Mon/Wed/Fri
        var workoutDates: [Date] = []
        for weekOffset in (1...6).reversed() {
            for dayOffset in [2, 4, 6] { // Mon=2, Wed=4, Fri=6 relative to Sun
                var comps = DateComponents()
                comps.weekOfYear = -weekOffset
                comps.weekday = dayOffset
                if let d = calendar.nextDate(after: today, matching: comps, matchingPolicy: .nextTime, direction: .backward) {
                    workoutDates.append(d)
                }
            }
        }
        workoutDates.sort()

        // Cycle Upper A → Lower A → Upper B → Lower B
        let templateCycle = [
            upperTemplates.first,
            lowerTemplates.first,
            upperTemplates.last ?? upperTemplates.first,
            lowerTemplates.last ?? lowerTemplates.first
        ].compactMap { $0 }

        // Find completed queued sessions to link logs to
        let queuedDescriptor = FetchDescriptor<QueuedSession>()
        var queuedSessions = try context.fetch(queuedDescriptor)

        for (i, date) in workoutDates.enumerated() {
            let template = templateCycle[i % templateCycle.count]
            let sessionNumber = (i / templateCycle.count) + 1

            // Find or use the matching queued session
            let matchingSession = queuedSessions.first {
                $0.sessionTemplate?.id == template.id && $0.status == .queued
            }

            let log = WorkoutLog(
                completedAt: date.addingTimeInterval(3600 + Double.random(in: 0...1800)), // ~1–1.5h in
                durationMinutes: Int.random(in: 45...75),
                sets: [],
                queuedSession: matchingSession
            )
            context.insert(log)

            if let session = matchingSession {
                session.status = .completed
                session.workoutLog = log
                queuedSessions.removeAll { $0.id == session.id }
            }

            // Build sets with progressive overload across weeks
            let progressFactor = 1.0 + Double(i / templateCycle.count) * 0.025 // ~2.5% per week
            var setNumber = 1

            for entry in template.sortedEntries {
                let baseSets = sampleSets(
                    for: entry,
                    startingSetNumber: setNumber,
                    progressFactor: progressFactor,
                    sessionIndex: i
                )
                for set in baseSets {
                    context.insert(set)
                    log.sets.append(set)
                    setNumber += 1
                }
                setNumber = 1 // reset per exercise
            }
        }

        try context.save()

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(175, forKey: "userWeightLbs")
        print("[DevSeeder] Seeded \(workoutDates.count) workout logs.")
    }

    // MARK: - Set Generation

    // Rough starting weights by exercise ID
    private static let baseWeights: [UUID: Double] = [
        ExerciseLibrary.benchPressID:      135,
        ExerciseLibrary.ohpID:             85,
        ExerciseLibrary.backSquatID:       155,
        ExerciseLibrary.romanianDLID:      135,
        ExerciseLibrary.conventionalDLID:  185,
        ExerciseLibrary.barbellRowID:      115,
        ExerciseLibrary.inclineDBPressID:  60,
        ExerciseLibrary.pullUpsID:         0,   // bodyweight
        ExerciseLibrary.dipsID:            0,
        ExerciseLibrary.cableRowID:        120,
        ExerciseLibrary.dbShoulderPressID: 50,
        ExerciseLibrary.legPressID:        180,
        ExerciseLibrary.bulgarianSSID:     50,
        ExerciseLibrary.legCurlID:         90,
        ExerciseLibrary.hackSquatID:       135,
        ExerciseLibrary.gobletSquatID:     55,
        ExerciseLibrary.bicepCurlID:       35,
        ExerciseLibrary.lateralRaiseID:    20,
        ExerciseLibrary.tricepPushdownID:  50,
        ExerciseLibrary.facePullID:        40,
        ExerciseLibrary.cableChestFlyeID:  35,
        ExerciseLibrary.hammerCurlID:      35,
        ExerciseLibrary.ohTricepExtID:     60,
        ExerciseLibrary.legExtensionID:    90,
        ExerciseLibrary.calfRaiseID:       100,
        ExerciseLibrary.hipThrustID:       135,
        ExerciseLibrary.walkingLungesID:   40,
    ]

    private static func sampleSets(
        for entry: TemplateEntry,
        startingSetNumber: Int,
        progressFactor: Double,
        sessionIndex: Int
    ) -> [SetLog] {
        let topRep = ProgressionEngine.topRep(from: entry.targetReps)
        let bottomRep = ProgressionEngine.bottomRep(from: entry.targetReps)
        let baseWeight = baseWeights[entry.exerciseID] ?? 45

        var sets: [SetLog] = []
        for i in 0..<entry.targetSets {
            let weight = baseWeight > 0
                ? (baseWeight * progressFactor).rounded(toNearest: 5)
                : 0
            // Fatigue across sets: last set may drop a rep or two
            let maxReps = i == 0 ? topRep : max(bottomRep, topRep - i)
            let reps = Int.random(in: bottomRep...maxReps)
            let hitTarget = reps >= topRep

            let set = SetLog(
                exerciseID: entry.exerciseID,
                setNumber: i + 1,
                weightLbs: weight,
                reps: reps,
                targetReps: entry.targetReps,
                rpe: Int.random(in: 7...9),
                hitTarget: hitTarget
            )
            sets.append(set)
        }
        return sets
    }

    // MARK: - Wipe

    private static func wipeAll(in context: ModelContext) throws {
        try context.delete(model: WorkoutLog.self)
        try context.delete(model: SetLog.self)
        try context.delete(model: QueuedSession.self)
        try context.delete(model: SessionTemplate.self)
        try context.delete(model: TemplateEntry.self)
        try context.delete(model: Program.self)
        try context.delete(model: Exercise.self)
        try context.save()
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        (self / step).rounded() * step
    }
}
#endif
