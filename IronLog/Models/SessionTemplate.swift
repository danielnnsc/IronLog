import SwiftData
import Foundation

@Model
final class SessionTemplate {
    var id: UUID
    var name: String   // "Upper A", "Lower A", "Upper B", "Lower B"
    var order: Int     // 1–4, defines the repeating cycle position

    @Relationship(deleteRule: .cascade)
    var entries: [TemplateEntry]

    var sortedEntries: [TemplateEntry] {
        entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    init(
        id: UUID = UUID(),
        name: String,
        order: Int,
        entries: [TemplateEntry] = []
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.entries = entries
    }
}

@Model
final class TemplateEntry {
    var id: UUID
    var exerciseID: UUID   // References Exercise.id
    var targetSets: Int
    var targetReps: String // e.g. "6-8", "10-12"
    var notes: String?
    var sortOrder: Int

    var sessionTemplate: SessionTemplate?

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        targetSets: Int,
        targetReps: String,
        notes: String? = nil,
        sortOrder: Int
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.notes = notes
        self.sortOrder = sortOrder
    }
}
