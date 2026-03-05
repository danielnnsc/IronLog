import SwiftData
import Foundation

enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][rawValue]
    }

    var fullName: String {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][rawValue]
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}

@Model
final class Program {
    var id: UUID
    var createdAt: Date
    /// Stored as raw Int values (Weekday.rawValue) for SwiftData compatibility
    var scheduledDayValues: [Int]
    var isActive: Bool

    @Relationship(deleteRule: .cascade)
    var sessionTemplates: [SessionTemplate]

    var scheduledDays: [Weekday] {
        scheduledDayValues.compactMap { Weekday(rawValue: $0) }.sorted()
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        scheduledDays: [Weekday],
        isActive: Bool = true,
        sessionTemplates: [SessionTemplate] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scheduledDayValues = scheduledDays.map(\.rawValue)
        self.isActive = isActive
        self.sessionTemplates = sessionTemplates
    }
}
