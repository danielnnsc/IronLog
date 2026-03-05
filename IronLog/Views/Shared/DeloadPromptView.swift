import SwiftUI
import SwiftData

struct DeloadPromptView: View {

    let session: QueuedSession

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]

    @State private var confirmed = false
    @State private var isProcessing = false

    private var activeProgram: Program? { activePrograms.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.deload.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.deload)
                    }

                    // Explanation
                    VStack(spacing: Spacing.sm) {
                        Text("Deload Recommended")
                            .font(.ironLogTitle)
                            .foregroundColor(AppTheme.textPrimary)

                        Text("You've stalled on at least one lift for 2+ consecutive sessions. A 4-session deload at ~50% weight will allow recovery and break the plateau.")
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // What happens card
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        bulletRow(icon: "1.circle.fill", text: "4 deload sessions added to front of queue")
                        bulletRow(icon: "2.circle.fill", text: "Same exercises, ~50% weight, reduced volume")
                        bulletRow(icon: "3.circle.fill", text: "All future session dates shift forward")
                        bulletRow(icon: "4.circle.fill", text: "Nothing changes without your confirmation here")
                    }
                    .padding(Spacing.md)
                    .ironLogCard()
                    .padding(.horizontal, Spacing.md)

                    Spacer()

                    // Actions
                    VStack(spacing: Spacing.sm) {
                        Button {
                            insertDeload()
                        } label: {
                            if isProcessing {
                                HStack(spacing: Spacing.sm) {
                                    ProgressView().tint(.black)
                                    Text("Inserting Deload...")
                                }
                                .ironLogPrimaryButton()
                            } else {
                                Text("Yes, Insert Deload")
                                    .ironLogPrimaryButton()
                            }
                        }
                        .disabled(isProcessing)

                        Button {
                            dismiss()
                        } label: {
                            Text("Not Now — Keep Going")
                                .ironLogSecondaryButton()
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Deload")
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

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.deload)
                .font(.system(size: 16))
            Text(text)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func insertDeload() {
        guard let template = session.sessionTemplate,
              let program = activeProgram else { return }
        isProcessing = true

        Task { @MainActor in
            do {
                try ProgramGenerator.insertDeload(
                    for: template,
                    in: modelContext,
                    scheduledDays: program.scheduledDays
                )
                dismiss()
            } catch {
                isProcessing = false
            }
        }
    }
}
