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
        var inserted = false
        for exercise in allDefined where !existingIDs.contains(exercise.id) {
            context.insert(exercise)
            inserted = true
        }

        if inserted {
            try context.save()
        }
    }
}
