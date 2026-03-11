import SwiftData
import Foundation

@Model
final class WorkoutLog {
    var id: UUID
    var completedAt: Date
    var durationMinutes: Int?
    var notes: String?
    var customTitle: String?  // non-nil for ad-hoc activities (run, abs, etc.)

    @Relationship(deleteRule: .cascade)
    var sets: [SetLog]

    var queuedSession: QueuedSession?

    // MARK: - Computed

    var setsByExercise: [UUID: [SetLog]] {
        Dictionary(grouping: sets, by: \.exerciseID)
    }

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        sets: [SetLog] = [],
        queuedSession: QueuedSession? = nil,
        customTitle: String? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.sets = sets
        self.queuedSession = queuedSession
        self.customTitle = customTitle
    }
}
