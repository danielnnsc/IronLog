import SwiftUI
import SwiftData

struct AICustomizerView: View {

    let currentProgramType: ProgramType
    let scheduledDays: [Weekday]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SessionTemplate.order) private var templates: [SessionTemplate]

    @State private var userInput = ""
    @State private var isLoading = false
    @State private var pendingAction: ProgramAction?
    @State private var errorMessage: String?

    @FocusState private var inputFocused: Bool

    private var sessionNames: [String] {
        templates.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Prompt
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("What would you like to change?")
                            .font(.ironLogHeadline)
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Examples: \"Add abs to my workouts\" · \"Switch me to Push Pull Legs\" · \"Add a muscle group split leg day\"")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)

                        TextField("Describe what you'd like...", text: $userInput, axis: .vertical)
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(3...6)
                            .focused($inputFocused)
                            .padding(Spacing.md)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .padding(.horizontal, Spacing.md)

                    if let error = errorMessage {
                        Text(error)
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.red)
                            .padding(.horizontal, Spacing.md)
                    }

                    // Result preview
                    if let action = pendingAction {
                        actionPreviewCard(action: action)
                    }

                    Spacer()

                    // Generate button
                    if pendingAction == nil {
                        Button {
                            Task { await generate() }
                        } label: {
                            if isLoading {
                                HStack(spacing: Spacing.sm) {
                                    ProgressView().tint(.black)
                                    Text("Thinking...")
                                }
                                .ironLogPrimaryButton()
                            } else {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "sparkles")
                                    Text("Generate")
                                }
                                .ironLogPrimaryButton()
                            }
                        }
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        .opacity(userInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.top, Spacing.md)
            }
            .navigationTitle("AI Customizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear { inputFocused = true }
        }
    }

    // MARK: - Action Preview Card

    private func actionPreviewCard(action: ProgramAction) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.accent)
                Text("AI Suggestion")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.accent)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            Text(action.explanation)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: Spacing.sm) {
                Button {
                    applyAction(action)
                } label: {
                    Text("Apply")
                        .ironLogPrimaryButton()
                }

                Button {
                    pendingAction = nil
                    userInput = ""
                } label: {
                    Text("Cancel")
                        .ironLogSecondaryButton()
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Generate

    private func generate() async {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        inputFocused = false
        isLoading = true
        errorMessage = nil

        do {
            let action = try await AnthropicService.shared.customize(
                userMessage: userInput,
                currentProgram: currentProgramType,
                sessionNames: sessionNames
            )
            await MainActor.run { pendingAction = action }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Apply

    private func applyAction(_ action: ProgramAction) {
        let days = scheduledDays.isEmpty
            ? [Weekday.monday, .tuesday, .thursday, .friday]
            : scheduledDays

        switch action.kind {

        case .switchProgram:
            guard let typeRaw = action.programType,
                  let type = ProgramType(rawValue: typeRaw) else { return }
            try? ProgramGenerator.switchProgram(
                to: type,
                scheduledDays: days,
                context: modelContext
            )

        case .addExercises:
            guard let uuidStrings = action.exercisesToAdd,
                  let targetNames = action.targetSessionNames else { return }

            let exerciseUUIDs = uuidStrings.compactMap { UUID(uuidString: $0) }
            let targetTemplates = templates.filter { targetNames.contains($0.name) }

            for template in targetTemplates {
                let existingIDs = Set(template.entries.map(\.exerciseID))
                let nextOrder = (template.entries.map(\.sortOrder).max() ?? -1) + 1
                for (i, uuid) in exerciseUUIDs.enumerated() where !existingIDs.contains(uuid) {
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

        case .addSession:
            guard let typeRaw = action.programType,
                  let type = ProgramType(rawValue: typeRaw) else { return }
            let sessionName = action.targetSessionNames?.first
            try? ProgramGenerator.addSession(
                named: sessionName ?? "",
                from: type,
                context: modelContext,
                scheduledDays: days
            )
        }

        dismiss()
    }
}
