import SwiftUI

struct OnboardingTimeAwayView: View {
    @Binding var selection: TimeAway
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                Text("How long have you\nbeen away from the gym?")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xl)

                Text("This helps us calibrate your starting point.")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                ForEach(TimeAway.allCases) { option in
                    selectionRow(option: option)
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .ironLogPrimaryButton()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(AppTheme.background)
    }

    private func selectionRow(option: TimeAway) -> some View {
        let isSelected = selection == option
        return Button {
            selection = option
        } label: {
            HStack {
                Text(option.rawValue)
                    .font(.ironLogHeadline)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}
