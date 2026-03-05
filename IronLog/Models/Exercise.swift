import SwiftData
import Foundation

enum ExerciseTier: String, Codable, CaseIterable {
    case anchor
    case secondary
    case accessory

    var displayName: String {
        switch self {
        case .anchor: return "Anchor"
        case .secondary: return "Secondary"
        case .accessory: return "Accessory"
        }
    }

    /// Default rest target range in seconds
    var restRange: ClosedRange<Int> {
        switch self {
        case .anchor: return 150...180   // 2.5–3 min
        case .secondary: return 90...120
        case .accessory: return 60...90
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var tier: ExerciseTier
    var bodyRegion: String               // "upper" or "lower"
    var movementDescription: String
    var formCues: String
    var isBodyweight: Bool
    var suggestedStartWeightLbs: Double? // nil = no suggestion (bodyweight / cable stack)
    var alternativeIDs: [UUID]           // IDs of swap alternatives

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        tier: ExerciseTier,
        bodyRegion: String,
        movementDescription: String,
        formCues: String,
        isBodyweight: Bool = false,
        suggestedStartWeightLbs: Double? = nil,
        alternativeIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.tier = tier
        self.bodyRegion = bodyRegion
        self.movementDescription = movementDescription
        self.formCues = formCues
        self.isBodyweight = isBodyweight
        self.suggestedStartWeightLbs = suggestedStartWeightLbs
        self.alternativeIDs = alternativeIDs
    }
}
