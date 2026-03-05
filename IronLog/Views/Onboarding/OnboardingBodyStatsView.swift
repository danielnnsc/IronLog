import SwiftUI

struct OnboardingBodyStatsView: View {

    @Binding var weightLbs: Int
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: Spacing.sm) {
                Text("Your body stats")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xl)

                Text("Used to estimate calories burned and saved to Apple Health with each workout.")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.md) {

                // Weight
                statCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WEIGHT")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.5)
                            Text("\(weightLbs) lbs")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Spacer()

                        HStack(spacing: Spacing.sm) {
                            stepButton(icon: "minus") {
                                weightLbs = max(80, weightLbs - 5)
                            }
                            stepButton(icon: "plus") {
                                weightLbs = min(400, weightLbs + 5)
                            }
                        }
                    }
                }

                // Height
                statCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HEIGHT")
                                .font(.ironLogMicro)
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.5)
                            Text("\(heightFeet)'\(heightInches)\"")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(spacing: Spacing.xs) {
                            HStack(spacing: Spacing.sm) {
                                Text("ft")
                                    .font(.ironLogCaption)
                                    .foregroundColor(AppTheme.textTertiary)
                                    .frame(width: 20)
                                stepButton(icon: "minus") {
                                    heightFeet = max(4, heightFeet - 1)
                                }
                                stepButton(icon: "plus") {
                                    heightFeet = min(7, heightFeet + 1)
                                }
                            }
                            HStack(spacing: Spacing.sm) {
                                Text("in")
                                    .font(.ironLogCaption)
                                    .foregroundColor(AppTheme.textTertiary)
                                    .frame(width: 20)
                                stepButton(icon: "minus") {
                                    heightInches = max(0, heightInches - 1)
                                }
                                stepButton(icon: "plus") {
                                    heightInches = min(11, heightInches + 1)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: onNext) {
                    Text("Continue")
                        .ironLogPrimaryButton()
                }

                Button(action: onNext) {
                    Text("Skip for now")
                        .ironLogSecondaryButton()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(AppTheme.background)
    }

    private func statCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 40, height: 40)
                .background(AppTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }
}
