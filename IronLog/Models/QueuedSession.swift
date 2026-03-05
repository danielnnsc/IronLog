import SwiftData
import Foundation

enum SessionStatus: String, Codable {
    case queued
    case completed
    case skipped
}

@Model
final class QueuedSession {
    var id: UUID
    var queuePosition: Int        // 1 = next up; reordered on edits
    var designatedDate: Date?     // Loose suggestion — never a hard lock
    var isDeload: Bool
    var status: SessionStatus
    var sessionNumber: Int        // e.g. 7 = "Upper A – Session 7"

    var sessionTemplate: SessionTemplate?

    @Relationship(deleteRule: .nullify)
    var workoutLog: WorkoutLog?

    // MARK: - Computed

    var displayName: String {
        let base = sessionTemplate?.name ?? "Session"
        return isDeload ? "Deload – \(base)" : base
    }

    var isOverdue: Bool {
        guard let date = designatedDate, status == .queued else { return false }
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
    }

    var isToday: Bool {
        guard let date = designatedDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    init(
        id: UUID = UUID(),
        queuePosition: Int,
        designatedDate: Date? = nil,
        isDeload: Bool = false,
        status: SessionStatus = .queued,
        sessionNumber: Int,
        sessionTemplate: SessionTemplate? = nil
    ) {
        self.id = id
        self.queuePosition = queuePosition
        self.designatedDate = designatedDate
        self.isDeload = isDeload
        self.status = status
        self.sessionNumber = sessionNumber
        self.sessionTemplate = sessionTemplate
    }
}
