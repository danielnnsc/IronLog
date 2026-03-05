import SwiftUI
import SwiftData

struct ProgramDetailView: View {

    let definition: ProgramDefinition
    let scheduledDays: [Weekday]
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var showingSwitchConfirm = false
    @State private var selectedSessionName: String?
    @State private var showingAddSessionConfirm = false

    private var templates: [SessionTemplate] {
        ProgramGenerator(
            modelContext: modelContext,
            scheduledDays: scheduledDays,
            weeksToGenerate: 1,
            programType: definition.type
        ).buildTemplates(for: definition.type)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        headerSection
                        sessionList
                        actionButtons
                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle(definition.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .confirmationDialog(
                "Switch to \(definition.name)?",
                isPresented: $showingSwitchConfirm,
                titleVisibility: .visible
            ) {
                Button("Switch Program", role: .destructive) { switchProgram() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your queue will be rebuilt for \(definition.name). Your workout history is preserved.")
            }
            .confirmationDialog(
                "Add \"\(selectedSessionName ?? "")\" to your rotation?",
                isPresented: $showingAddSessionConfirm,
                titleVisibility: .visible
            ) {
                Button("Add Session") { addSession() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This session will be appended to the end of your current queue.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(definition.subtitle)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)

            Text(definition.description)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: Spacing.xs) {
                ForEach(definition.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.ironLogMicro)
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.surface2)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ironLogCard()
    }

    // MARK: - Session List

    private var sessionList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(templates, id: \.id) { template in
                sessionCard(template: template)
            }
        }
    }

    private func sessionCard(template: SessionTemplate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(template.name)
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button {
                    selectedSessionName = template.name
                    showingAddSessionConfirm = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("Add")
                            .font(.ironLogCaption)
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }

            Divider().background(AppTheme.border)

            ForEach(template.sortedEntries, id: \.id) { entry in
                let exercise = exercises.first { $0.id == entry.exerciseID }
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(tierColor(exercise?.tier))
                        .frame(width: 6, height: 6)
                    Text(exercise?.name ?? "Unknown")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text("\(entry.targetSets)×\(entry.targetReps)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                showingSwitchConfirm = true
            } label: {
                Text("Switch to \(definition.name)")
                    .ironLogPrimaryButton()
            }
        }
    }

    // MARK: - Actions

    private func switchProgram() {
        let days = scheduledDays.isEmpty
            ? [Weekday.monday, .tuesday, .thursday, .friday]
            : scheduledDays

        try? ProgramGenerator.switchProgram(
            to: definition.type,
            scheduledDays: days,
            weeksToGenerate: 8,
            context: modelContext
        )
        dismiss()
        onDismiss()
    }

    private func addSession() {
        guard let name = selectedSessionName else { return }
        let days = scheduledDays.isEmpty
            ? [Weekday.monday, .tuesday, .thursday, .friday]
            : scheduledDays

        try? ProgramGenerator.addSession(
            named: name,
            from: definition.type,
            context: modelContext,
            scheduledDays: days
        )
        dismiss()
    }

    private func tierColor(_ tier: ExerciseTier?) -> Color {
        switch tier {
        case .anchor:    return AppTheme.accent
        case .secondary: return AppTheme.blue
        case .accessory: return AppTheme.textTertiary
        case nil:        return AppTheme.textTertiary
        }
    }
}
