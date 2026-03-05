import SwiftData
import Foundation

@Model
final class SetLog {
    var id: UUID
    var exerciseID: UUID      // References Exercise.id
    var setNumber: Int
    var weightLbs: Double     // Always stored in lbs; UI converts to kg if needed
    var reps: Int
    var targetReps: String    // e.g. "6-8"
    var rpe: Int?             // 1–10, optional
    var hitTarget: Bool       // Computed at log time: reps >= top of targetReps range
    var restDurationSeconds: Int? // Actual rest taken before this set

    var workoutLog: WorkoutLog?

    // MARK: - Convenience

    var weightKg: Double { weightLbs * 0.453592 }

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        setNumber: Int,
        weightLbs: Double,
        reps: Int,
        targetReps: String,
        rpe: Int? = nil,
        hitTarget: Bool,
        restDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.weightLbs = weightLbs
        self.reps = reps
        self.targetReps = targetReps
        self.rpe = rpe
        self.hitTarget = hitTarget
        self.restDurationSeconds = restDurationSeconds
    }
}
