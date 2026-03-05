import SwiftUI

struct OnboardingTrainingDaysView: View {
    @Binding var daysPerWeek: Int
    let onNext: () -> Void

    private let range = 3...6

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                Text("How many days per week\nwill you train?")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xl)

                Text("4 days is optimal for this Upper/Lower program.")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Big number display
            VStack(spacing: Spacing.lg) {
                Text("\(daysPerWeek)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.accent)
                    .contentTransition(.numericText())
                    .animation(.bouncy, value: daysPerWeek)

                Text("days per week")
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textSecondary)

                // Stepper buttons
                HStack(spacing: Spacing.xl) {
                    Button {
                        if daysPerWeek > range.lowerBound {
                            daysPerWeek -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(daysPerWeek > range.lowerBound ? AppTheme.textPrimary : AppTheme.textTertiary)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.surface2)
                            .clipShape(Circle())
                    }
                    .disabled(daysPerWeek <= range.lowerBound)

                    Button {
                        if daysPerWeek < range.upperBound {
                            daysPerWeek += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(daysPerWeek < range.upperBound ? AppTheme.textPrimary : AppTheme.textTertiary)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.surface2)
                            .clipShape(Circle())
                    }
                    .disabled(daysPerWeek >= range.upperBound)
                }
            }

            Spacer()

            // Context note
            noteCard
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)

            Button(action: onNext) {
                Text("Continue")
                    .ironLogPrimaryButton()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(AppTheme.background)
    }

    private var noteCard: some View {
        let note: String
        switch daysPerWeek {
        case 3: note = "3 days: Each session covers more ground. Great if life is busy."
        case 4: note = "4 days: The sweet spot. Full Upper/Lower split, twice per week."
        case 5: note = "5 days: One session will repeat in the week."
        case 6: note = "6 days: High frequency. Make sure you're recovering well."
        default: note = ""
        }

        return HStack(spacing: Spacing.sm) {
            Image(systemName: "info.circle")
                .foregroundColor(AppTheme.accent)
            Text(note)
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(Spacing.md)
        .ironLogCard()
    }
}
