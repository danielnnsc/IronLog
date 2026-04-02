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
        case .anchor:
            let s = UserDefaults.standard.integer(forKey: "anchorRestSeconds")
            let v = s > 0 ? s : 165
            return v...v
        case .secondary:
            let s = UserDefaults.standard.integer(forKey: "secondaryRestSeconds")
            let v = s > 0 ? s : 105
            return v...v
        case .accessory:
            let s = UserDefaults.standard.integer(forKey: "accessoryRestSeconds")
            let v = s > 0 ? s : 75
            return v...v
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
    var isTimeBased: Bool?               // true for holds/planks — target is duration not reps
    var suggestedStartWeightLbs: Double? // nil = no suggestion (bodyweight / cable stack)
    var alternativeIDs: [UUID]           // IDs of swap alternatives
    var isCustom: Bool                   // true = user-created, not from ExerciseLibrary

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
        isTimeBased: Bool? = nil,
        suggestedStartWeightLbs: Double? = nil,
        alternativeIDs: [UUID] = [],
        isCustom: Bool = false
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
        self.isTimeBased = isTimeBased
        self.suggestedStartWeightLbs = suggestedStartWeightLbs
        self.alternativeIDs = alternativeIDs
        self.isCustom = isCustom
    }
}
