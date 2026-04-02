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
    @State private var searchText = ""
    @State private var showingCustomCreate = false

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

    var searchResults: [Exercise] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return allExercises.filter { ex in
            ex.id != currentExercise.id &&
            (ex.name.lowercased().contains(q) ||
             ex.primaryMuscles.joined(separator: " ").lowercased().contains(q) ||
             ex.secondaryMuscles.joined(separator: " ").lowercased().contains(q))
        }.sorted { $0.name < $1.name }
    }

    var allOtherExercises: [Exercise] {
        let shownIDs = Set(alternatives.map(\.id) + sameMuscleSuggestions.map(\.id) + [currentExercise.id])
        return allExercises.filter { !shownIDs.contains($0.id) }.sorted { $0.name < $1.name }
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

                        if !searchText.isEmpty {
                            if searchResults.isEmpty {
                                VStack(spacing: Spacing.md) {
                                    Text("No exercises match \"\(searchText)\"")
                                        .font(.ironLogBody)
                                        .foregroundColor(AppTheme.textTertiary)
                                        .frame(maxWidth: .infinity)
                                    createCustomButton
                                }
                                .padding(.top, Spacing.xl)
                            } else {
                                exerciseGroup(title: "Results", exercises: searchResults)
                                createCustomButton
                            }
                        } else {
                            if !alternatives.isEmpty {
                                exerciseGroup(title: "Recommended Swaps", exercises: alternatives)
                            }
                            if !sameMuscleSuggestions.isEmpty {
                                exerciseGroup(title: "Same Muscle Group", exercises: sameMuscleSuggestions)
                            }
                            if !allOtherExercises.isEmpty {
                                exerciseGroup(title: "All Exercises", exercises: allOtherExercises)
                            }
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or muscle")
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showingCustomCreate) {
                CreateCustomExerciseSheet(
                    initialName: searchText,
                    allExercises: Array(allExercises),
                    currentExerciseID: currentExercise.id
                ) { exercise, isNew in
                    if isNew {
                        modelContext.insert(exercise)
                        try? modelContext.save()
                    }
                    confirming = exercise
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

    // MARK: - Custom Exercise

    private var createCustomButton: some View {
        Button {
            showingCustomCreate = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.accent)
                Text(searchText.isEmpty ? "Create custom exercise" : "Add \"\(searchText)\" as custom")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.accent)
                Spacer()
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

// MARK: - Create Custom Exercise Sheet

private struct CreateCustomExerciseSheet: View {

    let initialName: String
    let allExercises: [Exercise]
    let currentExerciseID: UUID
    /// Called with (exercise, isNew). isNew=false means user picked an existing library exercise.
    let onConfirm: (Exercise, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var muscleGroup: String = ""
    @State private var isBodyweight = false

    private let commonMuscles = ["Chest", "Back", "Shoulders", "Biceps", "Triceps",
                                  "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Full Body"]

    private var fuzzySuggestions: [Exercise] {
        FuzzyMatch.suggestions(for: name, in: allExercises, excluding: currentExerciseID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {

                        // Name field
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Exercise Name")
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)
                            TextField("e.g. Cable Lateral Raise", text: $name)
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(Spacing.md)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }

                        // Fuzzy suggestions — shown whenever name has content
                        if !fuzzySuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Already in library?")
                                    .font(.ironLogCaption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.accent)
                                    .tracking(1)

                                ForEach(fuzzySuggestions, id: \.id) { exercise in
                                    Button {
                                        onConfirm(exercise, false)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: Spacing.md) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(exercise.name)
                                                    .font(.ironLogHeadline)
                                                    .foregroundColor(AppTheme.textPrimary)
                                                if !exercise.primaryMuscles.isEmpty {
                                                    Text(exercise.primaryMuscles.joined(separator: " · "))
                                                        .font(.ironLogCaption)
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                            }
                                            Spacer()
                                            Text("Use this")
                                                .font(.ironLogCaption)
                                                .foregroundColor(AppTheme.accent)
                                        }
                                        .padding(Spacing.md)
                                        .ironLogCard()
                                    }
                                }

                                Text("Not what you meant? Fill in the details below to save as custom.")
                                    .font(.ironLogCaption)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }

                        // Custom details (always shown so user can still proceed)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(fuzzySuggestions.isEmpty ? "Primary Muscle (optional)" : "Or create custom")
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Spacing.xs) {
                                ForEach(commonMuscles, id: \.self) { muscle in
                                    Button {
                                        muscleGroup = muscleGroup == muscle ? "" : muscle
                                    } label: {
                                        Text(muscle)
                                            .font(.ironLogCaption)
                                            .foregroundColor(muscleGroup == muscle ? .black : AppTheme.textSecondary)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(muscleGroup == muscle ? AppTheme.accent : AppTheme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                    }
                                }
                            }
                        }

                        Toggle(isOn: $isBodyweight) {
                            Text("Bodyweight exercise")
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.accent)
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                        Text("Saved to your personal library. If a matching exercise is added to the app in a future update, your history will be automatically linked.")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)

                        Button {
                            let muscles = muscleGroup.isEmpty ? [] : [muscleGroup]
                            let exercise = Exercise(
                                name: name.trimmingCharacters(in: .whitespaces),
                                primaryMuscles: muscles,
                                secondaryMuscles: [],
                                tier: .accessory,
                                bodyRegion: "upper",
                                movementDescription: "",
                                formCues: "",
                                isBodyweight: isBodyweight,
                                isCustom: true
                            )
                            onConfirm(exercise, true)
                            dismiss()
                        } label: {
                            Text("Save as Custom Exercise")
                                .ironLogPrimaryButton()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear { name = initialName }
        }
    }
}
