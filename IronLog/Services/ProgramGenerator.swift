import SwiftData
import Foundation

/// Generates a new Program with four SessionTemplates (Upper A, Lower A, Upper B, Lower B)
/// and a rolling queue of QueuedSessions mapped to the user's scheduled days.
struct ProgramGenerator {

    let modelContext: ModelContext
    let scheduledDays: [Weekday]
    let weeksToGenerate: Int

    // MARK: - Entry Point

    /// Creates, inserts, and saves a new active Program.
    @MainActor
    func generate() throws -> Program {
        // Deactivate any existing active program
        let existingDescriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
        let existing = try modelContext.fetch(existingDescriptor)
        for p in existing { p.isActive = false }

        // Build default session templates
        let templates = buildDefaultTemplates()
        for t in templates { modelContext.insert(t) }

        // Create the program
        let program = Program(scheduledDays: scheduledDays, sessionTemplates: templates)
        modelContext.insert(program)

        // Generate the session queue
        let sessions = buildQueue(templates: templates)
        for s in sessions { modelContext.insert(s) }

        try modelContext.save()
        return program
    }

    // MARK: - Default Session Templates

    private func buildDefaultTemplates() -> [SessionTemplate] {
        let upperA = buildUpperA()
        let lowerA = buildLowerA()
        let upperB = buildUpperB()
        let lowerB = buildLowerB()
        return [upperA, lowerA, upperB, lowerB]
    }

    private func buildUpperA() -> SessionTemplate {
        let template = SessionTemplate(name: "Upper A", order: 1)
        template.entries = [
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
        return template
    }

    private func buildLowerA() -> SessionTemplate {
        let template = SessionTemplate(name: "Lower A", order: 2)
        template.entries = [
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
        return template
    }

    private func buildUpperB() -> SessionTemplate {
        let template = SessionTemplate(name: "Upper B", order: 3)
        template.entries = [
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
        return template
    }

    private func buildLowerB() -> SessionTemplate {
        let template = SessionTemplate(name: "Lower B", order: 4)
        template.entries = [
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
        return template
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

    /// Returns the next N upcoming calendar dates that fall on one of the scheduled weekdays.
    /// N = weeksToGenerate × daysPerWeek
    private func upcomingScheduledDates() -> [Date] {
        let calendar = Calendar.current
        let targetCount = weeksToGenerate * scheduledDays.count
        var dates: [Date] = []
        var cursor = calendar.startOfDay(for: .now)

        while dates.count < targetCount {
            let rawWeekday = calendar.component(.weekday, from: cursor) - 1 // 0 = Sunday
            if let day = Weekday(rawValue: rawWeekday), scheduledDays.contains(day) {
                dates.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return dates
    }

    // MARK: - Deload Insertion

    /// Inserts 4 deload sessions at the front of the queue for the given template,
    /// shifting all existing queued sessions back by 4 positions and advancing their
    /// designated dates by one scheduling cycle.
    @MainActor
    static func insertDeload(
        for template: SessionTemplate,
        in context: ModelContext,
        scheduledDays: [Weekday]
    ) throws {
        // Fetch all currently queued sessions, sorted by position
        let descriptor = FetchDescriptor<QueuedSession>(
            predicate: #Predicate { $0.statusValue == "queued" },
            sortBy: [SortDescriptor(\.queuePosition)]
        )
        let existingSessions = try context.fetch(descriptor)

        // Shift existing sessions back by 4
        for s in existingSessions {
            s.queuePosition += 4
            if let date = s.designatedDate {
                s.designatedDate = nextScheduledDate(after: date, scheduledDays: scheduledDays, shift: 4)
            }
        }

        // Find the deload start date (next 4 scheduled days from today)
        let deloadDates = nextNScheduledDates(from: .now, scheduledDays: scheduledDays, count: 4)

        // Insert 4 deload sessions
        for (i, date) in deloadDates.enumerated() {
            let deload = QueuedSession(
                queuePosition: i + 1,
                designatedDate: date,
                isDeload: true,
                sessionNumber: 0, // deload sessions don't count toward session numbers
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

    private static func nextNScheduledDates(from start: Date, scheduledDays: [Weekday], count: Int) -> [Date] {
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
