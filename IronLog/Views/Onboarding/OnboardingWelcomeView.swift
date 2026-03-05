import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 72))
                    .foregroundColor(AppTheme.accent)

                VStack(spacing: Spacing.sm) {
                    Text("IronLog")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your personal lifting program,\nadapted as you grow stronger.")
                        .font(.ironLogBody)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    featureRow(icon: "bolt.fill", text: "Personalized Upper/Lower split")
                    featureRow(icon: "chart.line.uptrend.xyaxis", text: "Tracks your progress over time")
                    featureRow(icon: "brain.head.profile", text: "Adapts when you stall or rest")
                    featureRow(icon: "iphone", text: "Fully local — no account needed")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .ironLogCard()
                .padding(.horizontal, Spacing.md)

                Button(action: onNext) {
                    Text("Let's build your program")
                        .ironLogPrimaryButton()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(AppTheme.background)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
