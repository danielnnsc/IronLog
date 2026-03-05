import Foundation

/// Handles all progressive overload decisions, weight recommendations, and stall detection.
/// Pure business logic — no SwiftData imports; operates on model instances passed in.
struct ProgressionEngine {

    // MARK: - Rep Range Parsing

    /// Parses "6-8" → 8 (top of range). Handles em-dashes and en-dashes.
    static func topRep(from targetReps: String) -> Int {
        let parts = targetReps.components(separatedBy: CharacterSet(charactersIn: "-–—"))
        let cleaned = parts.last?.trimmingCharacters(in: .whitespaces) ?? ""
        return Int(cleaned) ?? 0
    }

    /// Parses "6-8" → 6 (bottom of range).
    static func bottomRep(from targetReps: String) -> Int {
        let parts = targetReps.components(separatedBy: CharacterSet(charactersIn: "-–—"))
        let cleaned = parts.first?.trimmingCharacters(in: .whitespaces) ?? ""
        return Int(cleaned) ?? 0
    }

    // MARK: - Hit Target Check

    /// Returns true if ALL sets hit the top of the target rep range.
    static func hitTopOfRange(sets: [SetLog], targetReps: String) -> Bool {
        guard !sets.isEmpty else { return false }
        let top = topRep(from: targetReps)
        return sets.allSatisfy { $0.reps >= top }
    }

    // MARK: - Weight Recommendation

    /// Returns the recommended weight (in lbs) for the next session.
    ///
    /// - Session 1 & 2 are calibration: use the exercise's suggested starting weight.
    /// - Session 3+: look at the last completed sets and apply the progression rule.
    static func recommendedWeight(
        for exerciseID: UUID,
        nextSessionNumber: Int,
        exercise: Exercise,
        priorLogs: [WorkoutLog]
    ) -> Double? {
        // Calibration sessions
        if nextSessionNumber <= 2 {
            return exercise.suggestedStartWeightLbs
        }

        // Find all sets for this exercise, sorted newest first
        let allSets = priorLogs
            .flatMap { $0.sets }
            .filter { $0.exerciseID == exerciseID }
            .sorted { ($0.workoutLog?.completedAt ?? .distantPast) > ($1.workoutLog?.completedAt ?? .distantPast) }

        guard let mostRecentSet = allSets.first,
              let mostRecentDate = mostRecentSet.workoutLog?.completedAt else {
            return exercise.suggestedStartWeightLbs
        }

        // All sets from the most recent session for this exercise
        let lastSessionSets = allSets.filter {
            guard let date = $0.workoutLog?.completedAt else { return false }
            return Calendar.current.isDate(date, inSameDayAs: mostRecentDate)
        }

        let lastWeight = mostRecentSet.weightLbs

        // Check if user consistently hit high RPE (9–10) — secondary signal for deload
        let avgRPE = lastSessionSets.compactMap(\.rpe).reduce(0, +)
        let rpeCount = lastSessionSets.compactMap(\.rpe).count
        let highRPE = rpeCount > 0 && (Double(avgRPE) / Double(rpeCount)) >= 9.0

        if highRPE {
            // Don't add weight if RPE was consistently very high even if reps were hit
            return lastWeight
        }

        if hitTopOfRange(sets: lastSessionSets, targetReps: mostRecentSet.targetReps) {
            return lastWeight + progressionIncrement(for: exercise)
        }

        return lastWeight
    }

    // MARK: - Progression Increment

    /// Returns the weight increase in lbs for a successful session.
    static func progressionIncrement(for exercise: Exercise) -> Double {
        if exercise.isBodyweight { return 0 }
        switch exercise.bodyRegion {
        case "lower": return 10.0
        default:      return 5.0
        }
    }

    // MARK: - Stall Detection

    /// Returns true if the user has failed to progress on this exercise for 2 or more
    /// consecutive sessions. This triggers a deload suggestion.
    static func isStalled(
        exerciseID: UUID,
        priorLogs: [WorkoutLog],
        minimumSessions: Int = 2
    ) -> Bool {
        // Find logs that contain this exercise, sorted newest first
        let relevantLogs = priorLogs
            .filter { $0.sets.contains { $0.exerciseID == exerciseID } }
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(minimumSessions + 1) // Need one extra to compare against

        guard relevantLogs.count >= minimumSessions else { return false }

        // Extract the max weight logged per session for this exercise
        let weights: [Double] = relevantLogs.compactMap { log in
            log.sets
                .filter { $0.exerciseID == exerciseID }
                .map(\.weightLbs)
                .max()
        }

        guard weights.count >= minimumSessions else { return false }

        // Stall = no weight increase across the tracked sessions
        let maxWeight = weights.max() ?? 0
        let minWeight = weights.min() ?? 0
        return maxWeight == minWeight
    }

    // MARK: - Long Absence Detection

    /// Returns true if the most recent completed session was more than 14 days ago.
    static func hasLongAbsence(priorLogs: [WorkoutLog], thresholdDays: Int = 14) -> Bool {
        guard let lastLog = priorLogs.max(by: { $0.completedAt < $1.completedAt }) else {
            return false
        }
        let daysSince = Calendar.current.dateComponents([.day], from: lastLog.completedAt, to: .now).day ?? 0
        return daysSince >= thresholdDays
    }

    // MARK: - Deload Weight

    /// Returns the deload weight for a given exercise (50% of last logged weight, rounded to nearest 5 lbs).
    static func deloadWeight(for exerciseID: UUID, priorLogs: [WorkoutLog]) -> Double? {
        let allSets = priorLogs
            .flatMap(\.sets)
            .filter { $0.exerciseID == exerciseID }

        guard let lastWeight = allSets.max(by: { $0.weightLbs < $1.weightLbs })?.weightLbs else {
            return nil
        }

        let raw = lastWeight * 0.5
        // Round to nearest 5 lbs
        return (raw / 5).rounded() * 5
    }

    // MARK: - PR Detection

    /// Returns any exercises where the user set a new weight PR in the given WorkoutLog.
    static func newPRs(in log: WorkoutLog, against priorLogs: [WorkoutLog]) -> [UUID] {
        var prs: [UUID] = []
        let priorSets = priorLogs.flatMap(\.sets)

        for set in log.sets {
            let previousBest = priorSets
                .filter { $0.exerciseID == set.exerciseID }
                .map(\.weightLbs)
                .max() ?? 0

            if set.weightLbs > previousBest {
                if !prs.contains(set.exerciseID) {
                    prs.append(set.exerciseID)
                }
            }
        }
        return prs
    }

    // MARK: - Rest Summary

    /// Computes average rest duration per tier for the Session Complete summary.
    static func averageRest(in log: WorkoutLog, exercises: [Exercise]) -> [ExerciseTier: Int] {
        var restByTier: [ExerciseTier: [Int]] = [:]

        for set in log.sets {
            guard let seconds = set.restDurationSeconds,
                  let exercise = exercises.first(where: { $0.id == set.exerciseID }) else { continue }
            restByTier[exercise.tier, default: []].append(seconds)
        }

        return restByTier.mapValues { values in
            values.reduce(0, +) / values.count
        }
    }

    // MARK: - Rotation Detection

    /// Returns true if the given template has been used for 4 or more weeks
    /// without rotating secondary/accessory exercises (6-week trigger).
    static func shouldSuggestRotation(
        templateID: UUID,
        priorLogs: [WorkoutLog],
        weeksThreshold: Int = 4
    ) -> Bool {
        let relevantLogs = priorLogs.filter { $0.queuedSession?.sessionTemplate?.id == templateID }
        guard let oldest = relevantLogs.min(by: { $0.completedAt < $1.completedAt })?.completedAt else {
            return false
        }
        let weeksSince = Calendar.current.dateComponents([.weekOfYear], from: oldest, to: .now).weekOfYear ?? 0
        return weeksSince >= weeksThreshold
    }
}
