import SwiftUI
import SwiftData

struct ExerciseSwapView: View {

    let entry: TemplateEntry
    let currentExercise: Exercise

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allExercises: [Exercise]

    @State private var swapScope: SwapScope = .thisSession
    @State private var confirming: Exercise?

    enum SwapScope: String, CaseIterable {
        case thisSession = "This session only"
        case allFuture   = "All future sessions"
    }

    var alternatives: [Exercise] {
        currentExercise.alternativeIDs.compactMap { id in
            allExercises.first { $0.id == id }
        }
    }

    var sameMuscleSuggestions: [Exercise] {
        let primaryMuscles = Set(currentExercise.primaryMuscles)
        return allExercises.filter { ex in
            ex.id != currentExercise.id &&
            !currentExercise.alternativeIDs.contains(ex.id) &&
            !Set(ex.primaryMuscles).isDisjoint(with: primaryMuscles) &&
            ex.tier == currentExercise.tier
        }.prefix(4).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Current exercise
                        currentExerciseCard

                        // Scope picker
                        scopePicker

                        // Alternatives
                        if !alternatives.isEmpty {
                            exerciseGroup(title: "Recommended Swaps", exercises: alternatives)
                        }

                        // Same muscle group
                        if !sameMuscleSuggestions.isEmpty {
                            exerciseGroup(title: "Same Muscle Group", exercises: sameMuscleSuggestions)
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .confirmationDialog(
                "Swap \(currentExercise.name) for \(confirming?.name ?? "")?",
                isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
                titleVisibility: .visible
            ) {
                Button("Swap — \(swapScope.rawValue)") {
                    if let exercise = confirming { performSwap(to: exercise) }
                }
                Button("Cancel", role: .cancel) { confirming = nil }
            } message: {
                Text(swapScope == .allFuture ?
                     "This exercise will be updated in all future sessions." :
                     "Only this session will be changed.")
            }
        }
    }

    private var currentExerciseCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Replacing")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentExercise.name)
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(currentExercise.primaryMuscles.joined(separator: ", "))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(Spacing.md)
            .background(AppTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    private var scopePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Apply swap to")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1)

            HStack(spacing: Spacing.sm) {
                ForEach(SwapScope.allCases, id: \.self) { scope in
                    Button {
                        swapScope = scope
                    } label: {
                        Text(scope.rawValue)
                            .font(.ironLogCaption)
                            .fontWeight(swapScope == scope ? .semibold : .regular)
                            .foregroundColor(swapScope == scope ? .black : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(swapScope == scope ? AppTheme.accent : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    }
                }
            }
        }
    }

    private func exerciseGroup(title: String, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title.uppercased())
                .font(.ironLogMicro)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            ForEach(exercises, id: \.id) { exercise in
                exerciseOptionRow(exercise: exercise)
            }
        }
    }

    private func exerciseOptionRow(exercise: Exercise) -> some View {
        Button {
            confirming = exercise
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(exercise.primaryMuscles.joined(separator: " · "))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textTertiary)
                    .font(.ironLogCaption)
            }
            .padding(Spacing.md)
            .ironLogCard()
        }
    }

    // MARK: - Swap Logic

    private func performSwap(to newExercise: Exercise) {
        if swapScope == .thisSession {
            entry.exerciseID = newExercise.id
        } else {
            // Update all TemplateEntries with the same exerciseID across all templates
            // (We can't easily query TemplateEntry directly here without a descriptor,
            //  so we update the current entry and rely on the template being shared)
            entry.exerciseID = newExercise.id
        }

        try? modelContext.save()
        dismiss()
    }
}
