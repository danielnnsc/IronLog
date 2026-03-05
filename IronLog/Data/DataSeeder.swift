import SwiftData
import Foundation

/// Seeds the exercise library into SwiftData on first launch.
/// Safe to call on every launch — exits immediately if already seeded.
@MainActor
struct DataSeeder {

    static func seedExercisesIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Exercise>()
        let count = try context.fetchCount(descriptor)
        guard count == 0 else { return }

        for exercise in ExerciseLibrary.allExercises() {
            context.insert(exercise)
        }
        try context.save()
    }
}
