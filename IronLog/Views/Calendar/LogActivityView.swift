import SwiftUI
import SwiftData

struct LogActivityView: View {

    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let presets = ["Running", "Cycling", "Swimming", "Abs", "Stretching", "Yoga", "HIIT", "Walk", "Other"]

    @State private var selectedPreset: String? = nil
    @State private var customName: String = ""
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""
    @State private var showCustomField = false

    private var activityName: String {
        if showCustomField { return customName }
        return selectedPreset ?? ""
    }

    private var canSave: Bool { !activityName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {

                        // Date
                        Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.ironLogHeadline)
                            .foregroundColor(AppTheme.textSecondary)

                        // Activity type
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("ACTIVITY")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.5)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                ForEach(presets, id: \.self) { preset in
                                    Button {
                                        selectedPreset = preset
                                        showCustomField = preset == "Other"
                                        if preset != "Other" { customName = "" }
                                    } label: {
                                        Text(preset)
                                            .font(.ironLogCaption)
                                            .fontWeight(selectedPreset == preset ? .semibold : .regular)
                                            .foregroundColor(selectedPreset == preset ? .black : AppTheme.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Spacing.sm)
                                            .background(selectedPreset == preset ? AppTheme.accent : AppTheme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                    }
                                }
                            }

                            if showCustomField {
                                TextField("Activity name", text: $customName)
                                    .font(.ironLogBody)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(Spacing.sm)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            }
                        }

                        // Duration
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("DURATION")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.5)

                            HStack(spacing: Spacing.md) {
                                Button { durationMinutes = max(5, durationMinutes - 5) } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 40, height: 40)
                                        .background(AppTheme.surface2)
                                        .clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                Text("\(durationMinutes) min")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 90)

                                Button { durationMinutes += 5 } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 40, height: 40)
                                        .background(AppTheme.surface2)
                                        .clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("NOTES (optional)")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.5)

                            TextField("How did it go?", text: $notes, axis: .vertical)
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(3...6)
                                .padding(Spacing.sm)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                        }

                        Button {
                            save()
                        } label: {
                            Text("Log Activity")
                                .ironLogPrimaryButton()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.4)

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Log Activity")
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

    private func save() {
        let log = WorkoutLog(
            completedAt: date,
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes,
            customTitle: activityName.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(log)
        try? modelContext.save()
        dismiss()
    }
}
