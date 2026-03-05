import SwiftUI
import SwiftData
import Charts

struct ProgressTrackingView: View {

    @Query(sort: \WorkoutLog.completedAt) private var allLogs: [WorkoutLog]
    @Query private var allExercises: [Exercise]

    @State private var selectedTab: ProgressTab = .charts
    @State private var selectedExerciseID: UUID? = ExerciseLibrary.benchPressID

    enum ProgressTab: String, CaseIterable {
        case charts  = "Charts"
        case history = "History"
    }

    private let keyLifts: [(String, UUID)] = [
        ("Bench", ExerciseLibrary.benchPressID),
        ("Squat", ExerciseLibrary.backSquatID),
        ("OHP",   ExerciseLibrary.ohpID),
        ("RDL",   ExerciseLibrary.romanianDLID),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    tabPicker
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)

                    if allLogs.isEmpty {
                        emptyState
                    } else {
                        switch selectedTab {
                        case .charts:  chartsTab
                        case .history: historyTab
                        }
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProgressTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.ironLogHeadline)
                        .foregroundColor(selectedTab == tab ? .black : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedTab == tab ? AppTheme.accent : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.textTertiary)
            Text("No data yet")
                .font(.ironLogTitle)
                .foregroundColor(AppTheme.textPrimary)
            Text("Complete your first session to see your progress charts here.")
                .font(.ironLogBody)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
        }
    }

    // MARK: - Charts Tab

    private var chartsTab: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Lift selector
                liftSelector
                    .padding(.horizontal, Spacing.md)

                // Chart
                if let exerciseID = selectedExerciseID {
                    exerciseChart(for: exerciseID)
                        .padding(.horizontal, Spacing.md)
                }

                // Stats cards for selected exercise
                if let exerciseID = selectedExerciseID {
                    exerciseStatsRow(for: exerciseID)
                        .padding(.horizontal, Spacing.md)
                }

                Spacer(minLength: Spacing.xl)
            }
            .padding(.top, Spacing.md)
        }
    }

    private var liftSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(keyLifts, id: \.1) { (name, id) in
                    Button {
                        selectedExerciseID = id
                    } label: {
                        Text(name)
                            .font(.ironLogCaption)
                            .fontWeight(selectedExerciseID == id ? .bold : .regular)
                            .foregroundColor(selectedExerciseID == id ? .black : AppTheme.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedExerciseID == id ? AppTheme.accent : AppTheme.surface)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func exerciseChart(for exerciseID: UUID) -> some View {
        let data = chartData(for: exerciseID)
        let exercise = allExercises.first { $0.id == exerciseID }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(exercise?.name ?? "")
                .font(.ironLogHeadline)
                .foregroundColor(AppTheme.textPrimary)

            if data.isEmpty {
                Text("No data yet for this exercise.")
                    .font(.ironLogBody)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(height: 200, alignment: .center)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight (lbs)", point.maxWeight)
                        )
                        .foregroundStyle(AppTheme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Weight (lbs)", point.maxWeight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight (lbs)", point.maxWeight)
                        )
                        .foregroundStyle(AppTheme.accent)
                        .symbolSize(30)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine().foregroundStyle(AppTheme.border)
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.ironLogMicro)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(AppTheme.border)
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(Int(val))")
                                    .font(.ironLogMicro)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(Spacing.md)
                .ironLogCard()
            }
        }
    }

    private func exerciseStatsRow(for exerciseID: UUID) -> some View {
        let data = chartData(for: exerciseID)
        let currentBest = data.map(\.maxWeight).max() ?? 0
        let starting = data.first?.maxWeight ?? 0
        let gain = currentBest - starting

        return HStack(spacing: Spacing.sm) {
            miniStat(value: "\(Int(currentBest)) lbs", label: "Current Best")
            miniStat(value: gain > 0 ? "+\(Int(gain)) lbs" : "—", label: "Total Gain")
            miniStat(value: "\(data.count)", label: "Sessions")
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.accent)
            Text(label)
                .font(.ironLogMicro)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .ironLogCard()
    }

    // MARK: - History Tab

    private var historyTab: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(allLogs.reversed()) { log in
                    historyRow(log: log)
                }
                Spacer(minLength: Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
    }

    private func historyRow(log: WorkoutLog) -> some View {
        NavigationLink {
            SessionHistoryDetailView(log: log, exercises: allExercises)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.queuedSession?.displayName ?? "Session")
                        .font(.ironLogHeadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(log.completedAt.formatted(.dateTime.weekday(.abbreviated).month().day().year()))
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(log.sets.count) sets")
                        .font(.ironLogCaption)
                        .foregroundColor(AppTheme.textSecondary)
                    if let duration = log.durationMinutes {
                        Text("\(duration)m")
                            .font(.ironLogCaption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.ironLogMicro)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(Spacing.md)
            .ironLogCard()
        }
    }

    // MARK: - Chart Data

    struct ChartPoint {
        let date: Date
        let maxWeight: Double
    }

    private func chartData(for exerciseID: UUID) -> [ChartPoint] {
        allLogs.compactMap { log -> ChartPoint? in
            let sets = log.sets.filter { $0.exerciseID == exerciseID }
            guard let max = sets.map(\.weightLbs).max() else { return nil }
            return ChartPoint(date: log.completedAt, maxWeight: max)
        }
    }
}
