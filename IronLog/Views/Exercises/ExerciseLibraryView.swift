import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {

    @Query private var exercises: [Exercise]
    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]

    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var selectedTier: ExerciseTier? = nil
    @State private var infoExercise: Exercise?
    @State private var addToSessionExercise: Exercise?

    private let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Glutes"]

    private var filtered: [Exercise] {
        exercises
            .filter { selectedTier == nil || $0.tier == selectedTier }
            .filter { muscle in
                guard let selectedMuscle else { return true }
                if selectedMuscle == "Core" { return muscle.bodyRegion == "core" }
                if selectedMuscle == "Arms" {
                    return muscle.primaryMuscles.contains(where: {
                        $0.contains("Bicep") || $0.contains("Tricep") || $0.contains("Brachial")
                    })
                }
                if selectedMuscle == "Shoulders" {
                    return muscle.primaryMuscles.contains(where: { $0.contains("Delt") })
                }
                return muscle.primaryMuscles.contains(where: { $0.localizedCaseInsensitiveContains(selectedMuscle) })
                    || muscle.secondaryMuscles.contains(where: { $0.localizedCaseInsensitiveContains(selectedMuscle) })
            }
            .filter {
                searchText.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.primaryMuscles.joined().localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.name < $1.name }
    }

    private var grouped: [(String, [Exercise])] {
        let tiers: [ExerciseTier] = [.anchor, .secondary, .accessory]
        return tiers.compactMap { tier in
            let exs = filtered.filter { $0.tier == tier }
            return exs.isEmpty ? nil : (tier.displayName, exs)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterChips

                    Divider().background(AppTheme.border)

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(grouped, id: \.0) { (tierName, exs) in
                                Section {
                                    ForEach(exs, id: \.id) { exercise in
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
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search by name or muscle")
            .sheet(item: $infoExercise) { ex in
                ExerciseInfoSheet(exercise: ex, onAdd: {
                    addToSessionExercise = ex
                })
            }
            .sheet(item: $addToSessionExercise) { ex in
                AddToSessionSheet(exercise: ex, activeProgram: activePrograms.first)
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    filterChip(label: "All", value: nil, binding: $selectedMuscle)
                    ForEach(muscleGroups, id: \.self) { muscle in
                        filterChip(label: muscle, value: muscle, binding: $selectedMuscle)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    tierChip(label: "All Tiers", value: nil)
                    ForEach(ExerciseTier.allCases, id: \.self) { tier in
                        tierChip(label: tier.displayName, value: tier)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private func filterChip(label: String, value: String?, binding: Binding<String?>) -> some View {
        let isSelected = binding.wrappedValue == value
        return Button { binding.wrappedValue = value } label: {
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

    private func tierChip(label: String, value: ExerciseTier?) -> some View {
        let isSelected = selectedTier == value
        return Button { selectedTier = value } label: {
            Text(label)
                .font(.ironLogCaption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? AppTheme.blue : AppTheme.surface)
                .clipShape(Capsule())
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            infoExercise = exercise
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

                Button {
                    addToSessionExercise = exercise
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
}

// MARK: - Add to Session Sheet

struct AddToSessionSheet: View {

    let exercise: Exercise
    let activeProgram: Program?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var sessions: [SessionTemplate] {
        activeProgram?.sessionTemplates.sorted { $0.order < $1.order } ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    ForEach(sessions, id: \.id) { template in
                        let alreadyAdded = template.entries.contains { $0.exerciseID == exercise.id }
                        Button {
                            addExercise(to: template)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.ironLogHeadline)
                                        .foregroundColor(alreadyAdded ? AppTheme.textTertiary : AppTheme.textPrimary)
                                    Text("\(template.entries.count) exercises")
                                        .font(.ironLogCaption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                if alreadyAdded {
                                    Text("Already added")
                                        .font(.ironLogMicro)
                                        .foregroundColor(AppTheme.textTertiary)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                        }
                        .disabled(alreadyAdded)
                        .listRowBackground(AppTheme.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add \(exercise.name) to...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private func addExercise(to template: SessionTemplate) {
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
        dismiss()
    }
}
