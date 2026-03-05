import SwiftUI
import SwiftData

struct AddMuscleGroupView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SessionTemplate.order) private var templates: [SessionTemplate]

    @State private var selectedGroup: MuscleGroupAddon? = nil
    @State private var selectedTemplateIDs: Set<PersistentIdentifier> = []
    @State private var applied = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {

                        // MARK: Muscle Group Picker
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("What would you like to add?")
                                .font(.ironLogHeadline)
                                .foregroundColor(AppTheme.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                ForEach(MuscleGroupAddon.allCases, id: \.self) { group in
                                    groupCard(group)
                                }
                            }
                        }

                        // MARK: Session Picker
                        if selectedGroup != nil {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Add to which sessions?")
                                    .font(.ironLogHeadline)
                                    .foregroundColor(AppTheme.textPrimary)

                                ForEach(templates, id: \.id) { template in
                                    sessionRow(template)
                                }
                            }
                        }

                        // MARK: Preview
                        if let group = selectedGroup, !selectedTemplateIDs.isEmpty {
                            previewCard(group: group)
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(Spacing.md)
                }

                // Apply button
                VStack {
                    Spacer()
                    if let group = selectedGroup, !selectedTemplateIDs.isEmpty {
                        Button { applyChanges(group: group) } label: {
                            Text(applied ? "Added!" : "Add Exercises")
                                .ironLogPrimaryButton()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.md)
                    }
                }
            }
            .navigationTitle("Customize Program")
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

    // MARK: - Group Card

    private func groupCard(_ group: MuscleGroupAddon) -> some View {
        let isSelected = selectedGroup == group
        return Button {
            selectedGroup = group
            selectedTemplateIDs = []
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: group.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : AppTheme.accent)
                Text(group.displayName)
                    .font(.ironLogCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
                Text("\(group.exerciseIDs.count) exercises")
                    .font(.ironLogMicro)
                    .foregroundColor(isSelected ? .black.opacity(0.6) : AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    // MARK: - Session Row

    private func sessionRow(_ template: SessionTemplate) -> some View {
        let isSelected = selectedTemplateIDs.contains(template.persistentModelID)
        let alreadyHas = selectedGroup.map { group in
            template.entries.contains { group.exerciseIDs.contains($0.exerciseID) }
        } ?? false

        return Button {
            if isSelected {
                selectedTemplateIDs.remove(template.persistentModelID)
            } else {
                selectedTemplateIDs.insert(template.persistentModelID)
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)
                    if alreadyHas {
                        Text("Already has some of these")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                Spacer()
            }
            .padding(Spacing.md)
            .ironLogCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Card

    private func previewCard(group: MuscleGroupAddon) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(AppTheme.green)
                Text("Will add")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.green)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            ForEach(group.exerciseNames, id: \.self) { name in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 6, height: 6)
                    Text(name)
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(AppTheme.green.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Apply

    private func applyChanges(group: MuscleGroupAddon) {
        let targetTemplates = templates.filter { selectedTemplateIDs.contains($0.persistentModelID) }

        for template in targetTemplates {
            let existingIDs = Set(template.entries.map(\.exerciseID))
            let nextOrder = (template.entries.map(\.sortOrder).max() ?? -1) + 1
            for (i, uuid) in group.exerciseIDs.enumerated() where !existingIDs.contains(uuid) {
                let entry = TemplateEntry(
                    exerciseID: uuid,
                    targetSets: 3,
                    targetReps: "12-15",
                    sortOrder: nextOrder + i
                )
                modelContext.insert(entry)
                template.entries.append(entry)
            }
        }
        try? modelContext.save()
        applied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }
}

// MARK: - Muscle Group Addon Catalog

enum MuscleGroupAddon: CaseIterable {
    case core, arms, glutes, calves

    var displayName: String {
        switch self {
        case .core:   return "Core & Abs"
        case .arms:   return "Arms"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        }
    }

    var icon: String {
        switch self {
        case .core:   return "figure.core.training"
        case .arms:   return "figure.strengthtraining.traditional"
        case .glutes: return "figure.run"
        case .calves: return "figure.walk"
        }
    }

    var exerciseIDs: [UUID] {
        switch self {
        case .core:
            return [ExerciseLibrary.cableCrunchID, ExerciseLibrary.hangingLegRaiseID, ExerciseLibrary.plankID]
        case .arms:
            return [ExerciseLibrary.preacherCurlID, ExerciseLibrary.ohTricepExtID, ExerciseLibrary.hammerCurlID]
        case .glutes:
            return [ExerciseLibrary.hipThrustID, ExerciseLibrary.walkingLungesID]
        case .calves:
            return [ExerciseLibrary.calfRaiseID]
        }
    }

    var exerciseNames: [String] {
        switch self {
        case .core:   return ["Cable Crunch", "Hanging Leg Raise", "Plank"]
        case .arms:   return ["Preacher Curl", "Overhead Tricep Extension", "Hammer Curl"]
        case .glutes: return ["Hip Thrust", "Walking Lunges"]
        case .calves: return ["Calf Raise"]
        }
    }
}
