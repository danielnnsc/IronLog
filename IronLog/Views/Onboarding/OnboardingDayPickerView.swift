import SwiftUI

struct OnboardingDayPickerView: View {
    let daysPerWeek: Int
    @Binding var selectedDays: Set<Weekday>
    let onNext: () -> Void

    var isValid: Bool { selectedDays.count == daysPerWeek }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                Text("Which days will\nyou train?")
                    .font(.ironLogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xl)

                Text("Select exactly \(daysPerWeek) day\(daysPerWeek == 1 ? "" : "s").")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 7), spacing: Spacing.sm) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    dayCell(day: day)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Selected count indicator
            HStack {
                Text("\(selectedDays.count)/\(daysPerWeek) days selected")
                    .font(.ironLogCaption)
                    .foregroundColor(isValid ? AppTheme.green : AppTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .ironLogPrimaryButton()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.4)
        }
        .background(AppTheme.background)
    }

    private func dayCell(day: Weekday) -> some View {
        let isSelected = selectedDays.contains(day)
        let canSelect = isSelected || selectedDays.count < daysPerWeek

        return Button {
            guard canSelect else { return }
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : (canSelect ? AppTheme.textPrimary : AppTheme.textTertiary))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
        .disabled(!canSelect)
    }
}
