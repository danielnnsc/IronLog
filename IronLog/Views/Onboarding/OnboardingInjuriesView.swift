import SwiftUI

struct OnboardingInjuriesView: View {
    @Binding var selectedInjuries: Set<Injury>
    let onNext: () -> Void

    @State private var freeText: String = ""
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                Text("Any injuries or\nlimitations?")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xl)

                Text("We'll keep these in mind when suggesting exercises.\nSkip if none apply.")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                ForEach(Injury.allCases) { injury in
                    injuryToggle(injury: injury)
                }

                // Free text field
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Other (optional)")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("Describe any other limitations...", text: $freeText, axis: .vertical)
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($textFieldFocused)
                        .lineLimit(2...4)
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: onNext) {
                    Text("Continue")
                        .ironLogPrimaryButton()
                }

                Button {
                    selectedInjuries = []
                    freeText = ""
                    onNext()
                } label: {
                    Text("Skip — no limitations")
                        .ironLogSecondaryButton()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(AppTheme.background)
        .onTapGesture { textFieldFocused = false }
    }

    private func injuryToggle(injury: Injury) -> some View {
        let isSelected = selectedInjuries.contains(injury)
        return Button {
            if isSelected {
                selectedInjuries.remove(injury)
            } else {
                selectedInjuries.insert(injury)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: injury.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
                    .frame(width: 24)

                Text(injury.rawValue)
                    .font(.ironLogHeadline)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : AppTheme.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}
