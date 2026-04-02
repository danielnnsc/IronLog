import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {

    @AppStorage("useKilograms") private var useKilograms = false
    @AppStorage("anchorRestSeconds") private var anchorRestSeconds = 165   // 2m45s default
    @AppStorage("secondaryRestSeconds") private var secondaryRestSeconds = 105
    @AppStorage("accessoryRestSeconds") private var accessoryRestSeconds = 75
    @AppStorage("reminderHour") private var reminderHour = 8               // 8 AM default
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("userWeightLbs") private var userWeightLbs = 175
    @AppStorage("userHeightFeet") private var userHeightFeet = 5
    @AppStorage("userHeightInchesRemainder") private var userHeightInchesRemainder = 10

    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirm = false
    @State private var showAbsencePrompt = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    @Query(sort: \WorkoutLog.completedAt, order: .reverse) private var logs: [WorkoutLog]

    private var hasLongAbsence: Bool {
        ProgressionEngine.hasLongAbsence(priorLogs: Array(logs))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    // Units
                    Section {
                        Toggle(isOn: $useKilograms) {
                            HStack {
                                settingIcon("scalemass.fill", color: AppTheme.blue)
                                Text("Display in Kilograms")
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                        .tint(AppTheme.accent)
                    } header: {
                        sectionHeader("Units")
                    }

                    // Rest Timer Defaults
                    Section {
                        restRow(label: "Anchor lifts", value: $anchorRestSeconds, range: 120...240)
                        restRow(label: "Secondary lifts", value: $secondaryRestSeconds, range: 60...180)
                        restRow(label: "Accessories", value: $accessoryRestSeconds, range: 30...120)
                    } header: {
                        sectionHeader("Rest Timer Defaults")
                    }

                    // Notifications
                    Section {
                        HStack {
                            settingIcon("bell.fill", color: AppTheme.orange)
                            Text("Reminder Time")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Picker("", selection: $reminderHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(AppTheme.accent)
                        }

                        HStack {
                            settingIcon("bell.badge.fill", color: notificationStatus == .authorized ? AppTheme.green : AppTheme.red)
                            Text("Rest Timer Alerts")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            if notificationStatus == .authorized {
                                Text("On")
                                    .foregroundColor(AppTheme.green)
                                    .font(.ironLogCaption)
                            } else {
                                Button("Enable in Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.ironLogCaption)
                                .foregroundColor(AppTheme.accent)
                            }
                        }
                    } header: {
                        sectionHeader("Notifications")
                    }

                    // Absence
                    if hasLongAbsence {
                        Section {
                            Button {
                                showAbsencePrompt = true
                            } label: {
                                HStack {
                                    settingIcon("exclamationmark.triangle.fill", color: AppTheme.orange)
                                    Text("Long Absence Detected")
                                        .foregroundColor(AppTheme.orange)
                                }
                            }
                        } header: {
                            sectionHeader("Alert")
                        }
                    }

                    // Body Stats
                    Section {
                        HStack {
                            settingIcon("figure.stand", color: AppTheme.blue)
                            Text("Weight")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("\(userWeightLbs) lbs")
                                .foregroundColor(AppTheme.accent)
                            Stepper("", value: $userWeightLbs, in: 80...400, step: 5)
                                .labelsHidden()
                        }

                        HStack {
                            settingIcon("ruler", color: AppTheme.blue)
                            Text("Height")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("\(userHeightFeet)'\(userHeightInchesRemainder)\"")
                                .foregroundColor(AppTheme.accent)
                            Stepper("", value: $userHeightFeet, in: 4...7)
                                .labelsHidden()
                            Stepper("", value: $userHeightInchesRemainder, in: 0...11)
                                .labelsHidden()
                        }
                    } header: {
                        sectionHeader("Body Stats")
                    } footer: {
                        Text("Used to estimate calories burned and synced to Apple Health.")
                            .font(.ironLogMicro)
                            .foregroundColor(AppTheme.textTertiary)
                    }

                    // About
                    Section {
                        HStack {
                            settingIcon("info.circle.fill", color: AppTheme.textTertiary)
                            Text("Version")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("1.0 MVP")
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    } header: {
                        sectionHeader("About")
                    }

                    // Danger Zone
                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                settingIcon("trash.fill", color: AppTheme.red)
                                Text("Reset Program")
                                    .foregroundColor(AppTheme.red)
                            }
                        }
                    } header: {
                        sectionHeader("Danger Zone")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(
                "Reset Program?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset — Delete All Data", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes your program, queue, and all workout history. This cannot be undone.")
            }
            .sheet(isPresented: $showAbsencePrompt) {
                AbsencePromptView()
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Components

    private func settingIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .foregroundColor(color)
            .frame(width: 24)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.ironLogCaption)
            .foregroundColor(AppTheme.textTertiary)
            .textCase(.uppercase)
    }

    private func restRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Text(formatSeconds(value.wrappedValue))
                .foregroundColor(AppTheme.accent)
            Stepper("", value: value, in: range, step: 15)
                .labelsHidden()
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return date.formatted(.dateTime.hour())
    }

    private func formatSeconds(_ seconds: Int) -> String {
        "\(seconds / 60)m \(seconds % 60 > 0 ? "\(seconds % 60)s" : "")"
    }

    // MARK: - Reset

    private func resetAllData() {
        try? modelContext.delete(model: WorkoutLog.self)
        try? modelContext.delete(model: QueuedSession.self)
        try? modelContext.delete(model: SessionTemplate.self)
        try? modelContext.delete(model: Program.self)
        try? modelContext.save()
        hasCompletedOnboarding = false
    }
}
