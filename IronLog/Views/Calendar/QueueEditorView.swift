import SwiftUI
import SwiftData

struct QueueEditorView: View {

    let sessions: [QueuedSession]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var orderedSessions: [QueuedSession] = []

    private var queuedOnly: [QueuedSession] {
        orderedSessions.filter { $0.status == .queued }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    ForEach(queuedOnly) { session in
                        queueRow(session: session)
                            .listRowBackground(AppTheme.surface)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onMove { indices, destination in
                        orderedSessions.move(fromOffsets: indices, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Edit Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOrder()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            orderedSessions = sessions.sorted { $0.queuePosition < $1.queuePosition }
        }
    }

    private func queueRow(session: QueuedSession) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayName)
                    .font(.ironLogHeadline)
                    .foregroundColor(session.isDeload ? AppTheme.deload : AppTheme.textPrimary)

                if let date = session.designatedDate {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).month().day()))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            if session.isOverdue {
                Text("Overdue")
                    .font(.ironLogMicro)
                    .foregroundColor(AppTheme.orange)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private func saveOrder() {
        for (index, session) in orderedSessions.enumerated() {
            session.queuePosition = index + 1
        }
        try? modelContext.save()
    }
}
