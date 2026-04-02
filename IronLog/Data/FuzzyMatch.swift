import Foundation

/// Simple fuzzy matching for exercise names.
/// Returns a score from 0.0 (no match) to 1.0 (exact match).
enum FuzzyMatch {

    /// Score threshold for DataSeeder auto-linking (conservative — avoids false migrations).
    static let autoLinkThreshold: Double = 0.70

    /// Score threshold for UI suggestions (liberal — show helpful hints).
    static let suggestionThreshold: Double = 0.35

    static func score(_ query: String, against target: String) -> Double {
        let q = normalized(query)
        let t = normalized(target)

        guard !q.isEmpty, !t.isEmpty else { return 0 }
        if q == t { return 1.0 }
        if t.contains(q) || q.contains(t) { return 0.85 }

        let qWords = words(q)
        let tWords = words(t)
        guard !qWords.isEmpty, !tWords.isEmpty else { return 0 }

        let overlap = qWords.intersection(tWords)
        if overlap.isEmpty { return 0 }

        // Jaccard-style: overlap / union, boosted when all query words are present
        let union = Double(qWords.union(tWords).count)
        let base = Double(overlap.count) / union

        // Bonus if every query word appears in the target
        let allQWordsPresent = qWords.isSubset(of: tWords)
        return allQWordsPresent ? min(1.0, base + 0.2) : base
    }

    /// Top matches from a list, sorted by score descending, above the suggestion threshold.
    static func suggestions(for query: String, in exercises: [Exercise], excluding: UUID? = nil) -> [Exercise] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return exercises
            .filter { $0.id != excluding && !$0.isCustom }
            .map { (exercise: $0, score: score(query, against: $0.name)) }
            .filter { $0.score >= suggestionThreshold }
            .sorted { $0.score > $1.score }
            .prefix(4)
            .map(\.exercise)
    }

    // MARK: - Helpers

    private static func normalized(_ s: String) -> String {
        s.lowercased()
         .replacingOccurrences(of: "-", with: " ")
         .replacingOccurrences(of: "'", with: "")
         .replacingOccurrences(of: "(", with: "")
         .replacingOccurrences(of: ")", with: "")
         .trimmingCharacters(in: .whitespaces)
    }

    private static func words(_ s: String) -> Set<String> {
        // Strip common filler words that add noise
        let stopWords: Set<String> = ["the", "a", "an", "and", "with", "to", "of", "for"]
        return Set(
            s.components(separatedBy: .whitespaces)
             .map { $0.trimmingCharacters(in: .punctuationCharacters) }
             .filter { !$0.isEmpty && !stopWords.contains($0) }
        )
    }
}
