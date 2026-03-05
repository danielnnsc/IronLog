import Foundation

// MARK: - Program Type

enum ProgramType: String, CaseIterable, Identifiable {
    case upperLower      = "upperLower"
    case pushPullLegs    = "pushPullLegs"
    case fullBody        = "fullBody"
    case muscleGroupSplit = "muscleGroupSplit"
    case stronglifts     = "stronglifts"
    case arnoldSplit     = "arnoldSplit"
    case phul            = "phul"

    var id: String { rawValue }
}

// MARK: - Program Definition

struct ProgramDefinition {
    let type: ProgramType
    let name: String
    let subtitle: String
    let description: String
    let tags: [String]
    let daysRange: ClosedRange<Int>
    let sessionsPerCycle: Int

    /// SF Symbol name for the program card icon
    let icon: String
}

// MARK: - Catalog

enum ProgramLibrary {

    static let all: [ProgramDefinition] = [
        ProgramDefinition(
            type: .upperLower,
            name: "Upper / Lower",
            subtitle: "4-day · Strength & Hypertrophy",
            description: "Alternates upper and lower body sessions across 4 days. Balances frequency and recovery — each muscle group trained twice per week. Great for intermediate lifters chasing both size and strength.",
            tags: ["Strength", "Hypertrophy", "Intermediate"],
            daysRange: 4...4,
            sessionsPerCycle: 4,
            icon: "arrow.up.arrow.down"
        ),
        ProgramDefinition(
            type: .pushPullLegs,
            name: "Push / Pull / Legs",
            subtitle: "3-day cycle · High Volume",
            description: "Groups muscles by movement pattern: pushing muscles (chest, shoulders, triceps), pulling muscles (back, biceps), and legs. Each session is highly focused. Run 3 days on, 1 day off or 6 days on, 1 day off.",
            tags: ["Hypertrophy", "Volume", "Intermediate"],
            daysRange: 3...6,
            sessionsPerCycle: 3,
            icon: "arrow.triangle.2.circlepath"
        ),
        ProgramDefinition(
            type: .fullBody,
            name: "Full Body",
            subtitle: "3-day · Beginner-Friendly",
            description: "Each session trains all major muscle groups with compound movements. High frequency (each muscle group 3x/week), lower volume per session. Ideal for beginners or anyone training 3 days a week.",
            tags: ["Strength", "Beginner-Friendly", "Efficient"],
            daysRange: 3...3,
            sessionsPerCycle: 3,
            icon: "figure.strengthtraining.functional"
        ),
        ProgramDefinition(
            type: .muscleGroupSplit,
            name: "Muscle Group Split",
            subtitle: "5-day · Hypertrophy Focus",
            description: "Dedicates each session to one muscle group: Chest, Back, Shoulders, Arms, Legs. Maximum volume per muscle group per session. Best for experienced lifters focused on bodybuilding-style hypertrophy.",
            tags: ["Hypertrophy", "Advanced", "Bodybuilding"],
            daysRange: 5...5,
            sessionsPerCycle: 5,
            icon: "person.crop.rectangle.stack"
        ),
        ProgramDefinition(
            type: .stronglifts,
            name: "Stronglifts 5×5",
            subtitle: "2-day cycle · Strength",
            description: "Two alternating sessions of 5 sets × 5 reps on the big compound lifts. Linear progression — add weight every session. The most proven beginner strength program. Barbell-only.",
            tags: ["Strength", "Beginner-Friendly", "Barbell"],
            daysRange: 3...3,
            sessionsPerCycle: 2,
            icon: "dumbbell.fill"
        ),
        ProgramDefinition(
            type: .arnoldSplit,
            name: "Arnold Split",
            subtitle: "3-day cycle · High Volume",
            description: "Chest+Back, Shoulders+Arms, Legs — run twice per week for a 6-day program. Pairs antagonist muscle groups (chest & back) in the same session for maximum pump and efficiency. Arnold's classic routine.",
            tags: ["Hypertrophy", "Volume", "Advanced"],
            daysRange: 6...6,
            sessionsPerCycle: 3,
            icon: "medal.fill"
        ),
        ProgramDefinition(
            type: .phul,
            name: "PHUL",
            subtitle: "4-day · Power + Hypertrophy",
            description: "Power Hypertrophy Upper Lower. Two power days (low reps, heavy weight) and two hypertrophy days (moderate weight, higher volume). Best of both worlds for intermediate lifters wanting strength and size.",
            tags: ["Strength", "Hypertrophy", "Intermediate"],
            daysRange: 4...4,
            sessionsPerCycle: 4,
            icon: "chart.bar.fill"
        ),
    ]

    static func definition(for type: ProgramType) -> ProgramDefinition {
        all.first { $0.type == type }!
    }
}
