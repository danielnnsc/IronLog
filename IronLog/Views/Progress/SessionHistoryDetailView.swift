import SwiftUI
import SwiftData

struct SessionHistoryDetailView: View {

    @Bindable var log: WorkoutLog
    let exercises: [Exercise]

    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var editingSetID: UUID? = nil
    @State private var editWeight: Double = 0
    @State private var editReps: Int = 0
    @State private var addingSetForExerciseID: UUID? = nil
    @State private var newSetWeight: Double = 0
    @State private var newSetReps: Int = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header stats
                    HStack(spacing: Spacing.sm) {
                        statTile(value: "\(log.sets.count)", label: "Sets")
                        statTile(value: volume, label: "Volume lbs")
                        durationTile
                    }

                    // Sets per exercise
                    let grouped = Dictionary(grouping: log.sets, by: \.exerciseID)
                    ForEach(Array(grouped.keys), id: \.self) { exerciseID in
                        if let sets = grouped[exerciseID] {
                            exerciseCard(exerciseID: exerciseID, sets: sets)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Notes")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)

                        if isEditing {
                            TextField("Add notes...", text: Binding(
                                get: { log.notes ?? "" },
                                set: { log.notes = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(3...6)
                                .padding(Spacing.sm)
                                .background(AppTheme.surface2)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                        } else if let notes = log.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Text("None")
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textTertiary)
                                .opacity(isEditing ? 1 : 0)
                        }
                    }
                    .padding(Spacing.md)
                    .ironLogCard()

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(log.queuedSession?.displayName ?? log.customTitle ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        editingSetID = nil
                        addingSetForExerciseID = nil
                        try? modelContext.save()
                    }
                    isEditing.toggle()
                }
                .foregroundColor(AppTheme.accent)
            }
        }
    }

    // MARK: - Volume

    private var volume: String {
        let v = log.sets.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        return v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }

    // MARK: - Stat Tiles

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.accent)
            Text(label)
                .font(.ironLogMicro)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .ironLogCard()
    }

    private var durationTile: some View {
        VStack(spacing: Spacing.xs) {
            if isEditing {
                HStack(spacing: Spacing.xs) {
                    Button {
                        log.durationMinutes = max(1, (log.durationMinutes ?? 0) - 5)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 28, height: 28)
                            .background(AppTheme.surface2)
                            .clipShape(Circle())
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Text("\(log.durationMinutes ?? 0)m")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accent)
                        .frame(minWidth: 44)
                    Button {
                        log.durationMinutes = (log.durationMinutes ?? 0) + 5
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 28, height: 28)
                            .background(AppTheme.surface2)
                            .clipShape(Circle())
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            } else {
                Text(log.durationMinutes.map { "\($0)m" } ?? "--")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accent)
            }
            Text("Duration")
                .font(.ironLogMicro)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Exercise Card

    private func exerciseCard(exerciseID: UUID, sets: [SetLog]) -> some View {
        let exercise = exercises.first { $0.id == exerciseID }
        let sorted = sets.sorted { $0.setNumber < $1.setNumber }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(exercise?.name ?? "Exercise")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(sorted, id: \.id) { set in
                let isBeingEdited = editingSetID == set.id

                VStack(spacing: Spacing.xs) {
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                            .frame(width: 44, alignment: .leading)

                        if !isBeingEdited {
                            Text("\(formatWeight(set.weightLbs)) lbs × \(set.reps) reps")
                                .font(.ironLogBody)
                                .foregroundColor(AppTheme.textPrimary)

                            if let rpe = set.rpe {
                                Text("Difficulty \(rpe)")
                                    .font(.ironLogCaption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Spacer()

                        if isEditing {
                            Button {
                                if isBeingEdited {
                                    editingSetID = nil
                                } else {
                                    editWeight = set.weightLbs
                                    editReps = set.reps
                                    editingSetID = set.id
                                    addingSetForExerciseID = nil
                                }
                            } label: {
                                Image(systemName: isBeingEdited ? "xmark.circle" : "pencil.circle")
                                    .foregroundColor(AppTheme.textTertiary)
                                    .font(.system(size: 18))
                            }

                            Button {
                                modelContext.delete(set)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(AppTheme.red)
                                    .font(.system(size: 16))
                                    .frame(width: 32, height: 32)
                            }
                        } else {
                            Image(systemName: set.hitTarget ? "checkmark.circle.fill" : "minus.circle")
                                .foregroundColor(set.hitTarget ? AppTheme.green : AppTheme.textTertiary)
                        }
                    }

                    // Inline edit controls
                    if isBeingEdited {
                        HStack(spacing: Spacing.sm) {
                            // Weight stepper
                            HStack(spacing: Spacing.xs) {
                                Button { editWeight = max(0, editWeight - 5) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                TextField("0", value: $editWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 64)
                                Button { editWeight += 5 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Divider().frame(height: 24).background(AppTheme.border)

                            // Reps stepper
                            HStack(spacing: Spacing.xs) {
                                Button { editReps = max(0, editReps - 1) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Text("\(editReps) reps")
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 56)
                                Button { editReps += 1 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Spacer()

                            Button {
                                set.weightLbs = editWeight
                                set.reps = editReps
                                set.hitTarget = editReps >= ProgressionEngine.topRep(from: set.targetReps)
                                editingSetID = nil
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.green)
                                    .font(.system(size: 26))
                            }
                        }
                        .padding(.leading, 44)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 6)
            }

            // Add Set
            if isEditing {
                let isAddingHere = addingSetForExerciseID == exerciseID
                if isAddingHere {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            // Weight stepper
                            HStack(spacing: Spacing.xs) {
                                Button { newSetWeight = max(0, newSetWeight - 5) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                TextField("0", value: $newSetWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 64)
                                Button { newSetWeight += 5 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Divider().frame(height: 24).background(AppTheme.border)

                            // Reps stepper
                            HStack(spacing: Spacing.xs) {
                                Button { newSetReps = max(0, newSetReps - 1) } label: {
                                    Image(systemName: "minus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Text("\(newSetReps) reps")
                                    .font(.ironLogBody).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 56)
                                Button { newSetReps += 1 } label: {
                                    Image(systemName: "plus").frame(width: 30, height: 30)
                                        .background(AppTheme.surface2).clipShape(Circle())
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Spacer()

                            Button {
                                let refSet = sorted.last
                                let newSet = SetLog(
                                    exerciseID: exerciseID,
                                    setNumber: sorted.count + 1,
                                    weightLbs: newSetWeight,
                                    reps: newSetReps,
                                    targetReps: refSet?.targetReps ?? "8-12",
                                    hitTarget: newSetReps >= ProgressionEngine.topRep(from: refSet?.targetReps ?? "8-12")
                                )
                                modelContext.insert(newSet)
                                log.sets.append(newSet)
                                try? modelContext.save()
                                addingSetForExerciseID = nil
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.green)
                                    .font(.system(size: 26))
                            }
                            .disabled(newSetReps == 0)
                            .opacity(newSetReps == 0 ? 0.4 : 1)
                        }

                        Button { addingSetForExerciseID = nil } label: {
                            Text("Cancel")
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                    .padding(.top, Spacing.xs)
                } else {
                    Button {
                        let lastSet = sorted.last
                        newSetWeight = lastSet?.weightLbs ?? 0
                        newSetReps = lastSet?.reps ?? 0
                        editingSetID = nil
                        addingSetForExerciseID = exerciseID
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14))
                            Text("Add Set")
                                .font(.ironLogCaption)
                        }
                        .foregroundColor(AppTheme.accent)
                        .padding(.top, Spacing.xs)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - Helpers

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
