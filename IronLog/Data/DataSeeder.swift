import SwiftData
import Foundation

/// Seeds the exercise library into SwiftData on first launch and adds new exercises on updates.
@MainActor
struct DataSeeder {

    static func seedExercisesIfNeeded(in context: ModelContext) throws {
        let allDefined = ExerciseLibrary.allExercises()

        // Fetch all existing exercise IDs in one query
        let descriptor = FetchDescriptor<Exercise>()
        let existing = try context.fetch(descriptor)
        let existingIDs = Set(existing.map(\.id))

        // Insert only exercises that don't exist yet (safe for fresh installs and updates)
        var newlyInserted: [Exercise] = []
        for exercise in allDefined where !existingIDs.contains(exercise.id) {
            context.insert(exercise)
            newlyInserted.append(exercise)
        }

        // Auto-link custom exercises: if a user-created exercise name matches a newly
        // added library exercise, migrate all TemplateEntry and SetLog references to
        // the library UUID, then delete the custom record.
        if !newlyInserted.isEmpty {
            let customExercises = existing.filter { $0.isCustom }
            for custom in customExercises {
                guard let match = newlyInserted
                    .map({ (exercise: $0, score: FuzzyMatch.score(custom.name, against: $0.name)) })
                    .filter({ $0.score >= FuzzyMatch.autoLinkThreshold })
                    .sorted(by: { $0.score > $1.score })
                    .first?.exercise else { continue }

                // Migrate TemplateEntry references
                let entries = try context.fetch(FetchDescriptor<TemplateEntry>())
                for entry in entries where entry.exerciseID == custom.id {
                    entry.exerciseID = match.id
                }

                // Migrate SetLog references
                let sets = try context.fetch(FetchDescriptor<SetLog>())
                for set in sets where set.exerciseID == custom.id {
                    set.exerciseID = match.id
                }

                context.delete(custom)
                print("[DataSeeder] Linked custom exercise '\(custom.name)' → library exercise '\(match.name)'")
            }
        }

        if !newlyInserted.isEmpty {
            try context.save()
        }
    }
}
