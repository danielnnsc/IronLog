import SwiftUI
import SwiftData

/// Inline ⓘ info sheet shown as a modal over any workout view.
struct ExerciseInfoSheet: View {

    let exercise: Exercise
    let onSwap: () -> Void

    @Query private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    var alternatives: [Exercise] {
        exercise.alternativeIDs.compactMap { id in
            exercises.first { $0.id == id }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Tier badge + exercise name
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            tierBadge
                            Text(exercise.name)
                                .font(.ironLogDisplay)
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        // Movement description
                        descriptionCard

                        // Muscles
                        musclesCard

                        // Form cues
                        formCuesCard

                        // Video placeholder
                        videoPlaceholder

                        // Swap button
                        Button {
                            dismiss()
                            onSwap()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Swap Exercise")
                            }
                            .ironLogSecondaryButton()
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Exercise Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textTertiary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        Text(exercise.tier.displayName.uppercased())
            .font(.ironLogMicro)
            .fontWeight(.bold)
            .tracking(1.5)
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tierColor)
            .clipShape(Capsule())
    }

    private var tierColor: Color {
        switch exercise.tier {
        case .anchor:    return AppTheme.accent
        case .secondary: return AppTheme.blue
        case .accessory: return AppTheme.textTertiary
        }
    }

    // MARK: - Cards

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("About")
            Text(exercise.movementDescription)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var musclesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Muscles")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                if !exercise.primaryMuscles.isEmpty {
                    muscleRow(label: "Primary", muscles: exercise.primaryMuscles, color: AppTheme.accent)
                }
                if !exercise.secondaryMuscles.isEmpty {
                    muscleRow(label: "Secondary", muscles: exercise.secondaryMuscles, color: AppTheme.textSecondary)
                }
            }
        }
    }

    private func muscleRow(label: String, muscles: [String], color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(label)
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 64, alignment: .leading)

            FlowLayout(spacing: Spacing.xs) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle)
                        .font(.ironLogCaption)
                        .foregroundColor(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var formCuesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Form Cues")

            let cues = exercise.formCues.components(separatedBy: ". ").filter { !$0.isEmpty }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(cues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text("\(i + 1)")
                            .font(.ironLogCaption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 20, height: 20)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(Circle())

                        Text(cue.hasSuffix(".") ? cue : cue + ".")
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var videoPlaceholder: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(AppTheme.surface2)
                    .frame(height: 160)
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("Demo video — coming soon")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.ironLogMicro)
            .fontWeight(.bold)
            .foregroundColor(AppTheme.textTertiary)
            .tracking(1.5)
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: containerWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
