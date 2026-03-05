import SwiftUI

struct OnboardingReviewView: View {
    let selectedDays: Set<Weekday>
    let isGenerating: Bool
    let error: String?
    let onConfirm: () -> Void

    private let sessions = [
        ("Upper A", "Bench Press · Row · Incline Press"),
        ("Lower A", "Squat · Leg Press · Romanian DL"),
        ("Upper B", "OHP · Pull-Ups · Cable Row"),
        ("Lower B", "Romanian DL · Split Squat · Leg Curl"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                Text("Your program")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top, Spacing.xl)

                let dayNames = selectedDays.sorted().map(\.shortName).joined(separator: " · ")
                Text(dayNames)
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Session preview cards
            VStack(spacing: Spacing.sm) {
                ForEach(sessions, id: \.0) { session in
                    sessionCard(name: session.0, exercises: session.1)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Cycle note
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.2.circlepath")
                    .foregroundColor(AppTheme.accent)
                Text("Sessions repeat in this order. You can swap any exercise any time.")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(Spacing.md)
            .ironLogCard()
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Spacer()

            if let error {
                Text(error)
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.red)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
            }

            Button(action: onConfirm) {
                if isGenerating {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .tint(.black)
                        Text("Building your program...")
                    }
                    .ironLogPrimaryButton()
                } else {
                    Text("Start Training")
                        .ironLogPrimaryButton()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
            .disabled(isGenerating)
        }
        .background(AppTheme.background)
    }

    private func sessionCard(name: String, exercises: String) -> some View {
        HStack(spacing: Spacing.md) {
            Text(name)
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.accent)
                .frame(width: 72, alignment: .leading)

            Text(exercises)
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(Spacing.md)
        .ironLogCard()
    }
}
