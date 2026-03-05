import SwiftUI
import SwiftData

struct ProgramBrowserView: View {

    let currentProgramType: ProgramType?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \QueuedSession.queuePosition) private var queuedSessions: [QueuedSession]

    @State private var selectedProgram: ProgramDefinition?
    @State private var showingAICustomizer = false

    private var scheduledDays: [Weekday] {
        // Infer from the current queue's designated dates
        let days = queuedSessions.compactMap { s -> Weekday? in
            guard let d = s.designatedDate else { return nil }
            let raw = Calendar.current.component(.weekday, from: d) - 1
            return Weekday(rawValue: raw)
        }
        return Array(Set(days)).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if let type = currentProgramType {
                            currentProgramCard(type: type)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Available Programs")
                                .font(.ironLogHeadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, Spacing.md)

                            ForEach(ProgramLibrary.all, id: \.type) { definition in
                                if definition.type != currentProgramType {
                                    programCard(definition: definition)
                                        .onTapGesture { selectedProgram = definition }
                                }
                            }
                        }

                        Button {
                            showingAICustomizer = true
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.accent)
                                Text("Ask AI to Customize")
                                    .font(.ironLogHeadline)
                                    .foregroundColor(AppTheme.accent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, Spacing.md)

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(item: $selectedProgram) { definition in
                ProgramDetailView(
                    definition: definition,
                    scheduledDays: scheduledDays,
                    onDismiss: { dismiss() }
                )
            }
            .sheet(isPresented: $showingAICustomizer) {
                AICustomizerView(
                    currentProgramType: currentProgramType ?? .upperLower,
                    scheduledDays: scheduledDays
                )
            }
        }
    }

    // MARK: - Current Program Card

    private func currentProgramCard(type: ProgramType) -> some View {
        let def = ProgramLibrary.definition(for: type)
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.green)
                    .font(.system(size: 14))
                Text("Current Program")
                    .font(.ironLogMicro)
                    .foregroundColor(AppTheme.green)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            Text(def.name)
                .font(.ironLogTitle)
                .foregroundColor(AppTheme.textPrimary)

            Text(def.subtitle)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)

            tagRow(tags: def.tags)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Program Card

    private func programCard(definition: ProgramDefinition) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: definition.icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            VStack(alignment: .leading, spacing: 4) {
                Text(definition.name)
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(definition.subtitle)
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
                tagRow(tags: definition.tags)
                    .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(Spacing.md)
        .ironLogCard()
        .padding(.horizontal, Spacing.md)
    }

    private func tagRow(tags: [String]) -> some View {
        HStack(spacing: Spacing.xs) {
            ForEach(tags, id: \.self) { tag in
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
}

// MARK: - Identifiable conformance for sheet
extension ProgramDefinition: Identifiable {
    public var id: ProgramType { type }
}
