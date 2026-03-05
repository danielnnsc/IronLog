import SwiftUI
import SwiftData

struct AddExerciseView: View {

    let session: QueuedSession
    let onAdded: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allExercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedTier: ExerciseTier? = nil
    @State private var exerciseToAdd: Exercise?

    private var existingIDs: Set<UUID> {
        Set(session.sessionTemplate?.entries.map(\.exerciseID) ?? [])
    }

    private var filtered: [Exercise] {
        allExercises
            .filter { !existingIDs.contains($0.id) }
            .filter { selectedTier == nil || $0.tier == selectedTier }
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.primaryMuscles.joined().localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.name < $1.name }
    }

    private var grouped: [(String, [Exercise])] {
        let tiers: [ExerciseTier] = [.anchor, .secondary, .accessory]
        return tiers.compactMap { tier in
            let exercises = filtered.filter { $0.tier == tier }
            return exercises.isEmpty ? nil : (tier.displayName, exercises)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tier filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            filterChip(label: "All", tier: nil)
                            ForEach(ExerciseTier.allCases, id: \.self) { tier in
                                filterChip(label: tier.displayName, tier: tier)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                    }

                    Divider().background(AppTheme.border)

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(grouped, id: \.0) { (tierName, exercises) in
                                Section {
                                    ForEach(exercises, id: \.id) { exercise in
                                        exerciseRow(exercise)
                                            .listRowBackground(AppTheme.surface)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                } header: {
                                    Text(tierName.uppercased())
                                        .font(.ironLogMicro)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.textTertiary)
                                        .tracking(1.5)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises or muscles")
            .confirmationDialog(
                "Add \(exerciseToAdd?.name ?? "") to \(session.sessionTemplate?.name ?? "this session")?",
                isPresented: Binding(get: { exerciseToAdd != nil }, set: { if !$0 { exerciseToAdd = nil } }),
                titleVisibility: .visible
            ) {
                Button("Add to all future \(session.sessionTemplate?.name ?? "") sessions") {
                    if let exercise = exerciseToAdd { addExercise(exercise) }
                }
                Button("Cancel", role: .cancel) { exerciseToAdd = nil }
            } message: {
                Text("The exercise will be added to every \(session.sessionTemplate?.name ?? "") session going forward.")
            }
        }
    }

    // MARK: - Filter Chip

    private func filterChip(label: String, tier: ExerciseTier?) -> some View {
        let isSelected = selectedTier == tier
        return Button { selectedTier = tier } label: {
            Text(label)
                .font(.ironLogCaption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? AppTheme.accent : AppTheme.surface)
                .clipShape(Capsule())
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button { exerciseToAdd = exercise } label: {
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
                Image(systemName: "plus.circle")
                    .foregroundColor(AppTheme.accent)
                    .font(.system(size: 20))
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textTertiary)
            Text("No exercises found")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Add Logic

    private func addExercise(_ exercise: Exercise) {
        guard let template = session.sessionTemplate else { return }

        let defaultReps: String
        let defaultSets: Int
        switch exercise.tier {
        case .anchor:    defaultSets = 4; defaultReps = "6-8"
        case .secondary: defaultSets = 3; defaultReps = "8-10"
        case .accessory: defaultSets = 3; defaultReps = "12-15"
        }

        let nextOrder = (template.entries.map(\.sortOrder).max() ?? -1) + 1
        let entry = TemplateEntry(
            exerciseID: exercise.id,
            targetSets: defaultSets,
            targetReps: defaultReps,
            sortOrder: nextOrder
        )

        modelContext.insert(entry)
        template.entries.append(entry)

        try? modelContext.save()
        exerciseToAdd = nil
        onAdded()
        dismiss()
    }
}
