import SwiftUI
import SwiftData

struct CalendarView: View {

    @Query(sort: \QueuedSession.queuePosition) private var allSessions: [QueuedSession]
    @Query(sort: \WorkoutLog.completedAt) private var allLogs: [WorkoutLog]

    @State private var displayedMonth = Date.now
    @State private var selectedDate: Date?
    @State private var showingQueueEditor = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        monthHeader
                        weekdayLabels
                        dayGrid
                        legend
                        if let date = selectedDate {
                            selectedDayDetail(for: date)
                        }
                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingQueueEditor = true } label: {
                        Text("Edit Schedule")
                            .font(.ironLogBody)
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingQueueEditor) {
                QueueEditorView(sessions: allSessions)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.ironLogTitle)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.ironLogMicro)
                    .foregroundColor(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = daysInMonth(for: displayedMonth)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let state = dayState(for: date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = calendar.isDate(date, inSameDayAs: selectedDate ?? .distantPast) ? nil : date
        } label: {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor(for: state, isToday: isToday))

                // State indicator dot
                Circle()
                    .fill(dotColor(for: state))
                    .frame(width: 6, height: 6)
                    .opacity(state == .rest ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(isSelected ? AppTheme.surface3 : (isToday ? AppTheme.surface2 : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .stroke(isSelected ? AppTheme.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Spacing.md) {
            legendItem(color: AppTheme.green, label: "Done")
            legendItem(color: AppTheme.accent, label: "Scheduled")
            legendItem(color: AppTheme.orange, label: "Overdue")
            legendItem(color: AppTheme.deload, label: "Deload")
            legendItem(color: AppTheme.textTertiary, label: "Skipped")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.ironLogMicro).foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Selected Day Detail

    private func selectedDayDetail(for date: Date) -> some View {
        let session = sessionForDate(date)
        let log = logForDate(date)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            if let log {
                completedDayDetail(log: log)
            } else if let session {
                scheduledDayDetail(session: session)
            } else {
                Text("Rest day")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(Spacing.md)
        .ironLogCard()
    }

    private func completedDayDetail(log: WorkoutLog) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.green)
                Text(log.queuedSession?.displayName ?? "Completed")
                    .font(.ironLogHeadline)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Text("\(log.sets.count) sets · \(Int(log.sets.reduce(0) { $0 + $1.weightLbs * Double($1.reps) })) lbs volume")
                .font(.ironLogCaption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func scheduledDayDetail(session: QueuedSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.displayName)
                    .font(.ironLogHeadline)
                    .foregroundColor(session.isOverdue ? AppTheme.orange : AppTheme.textPrimary)
                Text(session.isOverdue ? "Overdue — still queued" : "Scheduled")
                    .font(.ironLogCaption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            NavigationLink {
                DailySessionView(session: session, recentLogs: Array(allLogs))
            } label: {
                Text("View")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.accent)
            }
        }
    }

    // MARK: - Day State Logic

    enum DayState {
        case completed, scheduled, overdue, deload, skipped, rest
    }

    private func dayState(for date: Date) -> DayState {
        if logForDate(date) != nil { return .completed }
        if let session = sessionForDate(date) {
            if session.status == .skipped { return .skipped }
            if session.isDeload { return .deload }
            if session.isOverdue { return .overdue }
            return .scheduled
        }
        return .rest
    }

    private func sessionForDate(_ date: Date) -> QueuedSession? {
        allSessions.first {
            guard let d = $0.designatedDate else { return false }
            return calendar.isDate(d, inSameDayAs: date)
        }
    }

    private func logForDate(_ date: Date) -> WorkoutLog? {
        allLogs.first { calendar.isDate($0.completedAt, inSameDayAs: date) }
    }

    private func dotColor(for state: DayState) -> Color {
        switch state {
        case .completed:  return AppTheme.green
        case .scheduled:  return AppTheme.accent
        case .overdue:    return AppTheme.orange
        case .deload:     return AppTheme.deload
        case .skipped:    return AppTheme.textTertiary
        case .rest:       return .clear
        }
    }

    private func textColor(for state: DayState, isToday: Bool) -> Color {
        if isToday { return AppTheme.accent }
        switch state {
        case .rest:    return AppTheme.textSecondary
        default:       return AppTheme.textPrimary
        }
    }

    // MARK: - Calendar Math

    private func daysInMonth(for date: Date) -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        return days
    }
}
