import SwiftUI
import SwiftData

/// Shown on launch or from Settings when 2+ weeks have passed without logging.
/// User chooses to resume or insert a restart block.
struct AbsencePromptView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query(sort: \WorkoutLog.completedAt, order: .reverse) private var recentLogs: [WorkoutLog]

    @State private var isProcessing = false

    private var daysSinceLastSession: Int {
        guard let last = recentLogs.first else { return 0 }
        return Calendar.current.dateComponents([.day], from: last.completedAt, to: .now).day ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Spacer()

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 64))
                        .foregroundColor(AppTheme.orange)

                    VStack(spacing: Spacing.sm) {
                        Text("Welcome Back")
                            .font(.ironLogDisplay)
                            .foregroundColor(AppTheme.textPrimary)

                        Text("It's been \(daysSinceLastSession) days since your last session.")
                            .font(.ironLogHeadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        Text("After a longer break, starting lighter helps you avoid injury and get back in the groove quickly.")
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: Spacing.sm) {
                        // Recommended: restart block
                        Button {
                            insertRestartBlock()
                        } label: {
                            VStack(spacing: 4) {
                                Text("Restart Smart (Recommended)")
                                    .font(.ironLogHeadline)
                                Text("Insert 4 sessions at reduced weight to ease back in")
                                    .font(.ironLogCaption)
                                    .opacity(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(AppTheme.accent)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .disabled(isProcessing)

                        // Resume where left off
                        Button {
                            dismiss()
                        } label: {
                            Text("Resume Where I Left Off")
                                .ironLogSecondaryButton()
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Long Absence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func insertRestartBlock() {
        guard let program = activePrograms.first,
              let firstTemplate = program.sessionTemplates.min(by: { $0.order < $1.order }) else {
            dismiss()
            return
        }
        isProcessing = true
        Task { @MainActor in
            try? ProgramGenerator.insertDeload(
                for: firstTemplate,
                in: modelContext,
                scheduledDays: program.scheduledDays
            )
            dismiss()
        }
    }
}
