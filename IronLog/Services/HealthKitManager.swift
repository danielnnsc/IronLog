import HealthKit
import Foundation

/// Writes completed strength training workouts to Apple Health.
final class HealthKitManager {

    static let shared = HealthKitManager()
    private init() {}

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var typesToShare: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        try? await store.requestAuthorization(toShare: typesToShare, read: [])
    }

    // MARK: - Save Workout

    /// Saves a traditional strength training workout to Apple Health.
    /// - Parameters:
    ///   - startDate:       When the workout began.
    ///   - durationMinutes: Total workout duration.
    ///   - totalVolumeLbs:  Sum of (weight × reps) across all sets, used to estimate calories.
    func saveWorkout(startDate: Date, durationMinutes: Int, totalVolumeLbs: Double) async {
        guard isAvailable else { return }

        // Request auth each time — no-op if already granted.
        await requestAuthorization()

        let endDate = startDate.addingTimeInterval(Double(durationMinutes) * 60)

        // Estimate active calories: 5.0 METs × 75 kg body weight × hours
        let hours = max(Double(durationMinutes) / 60.0, 1.0 / 60.0)
        let estimatedKcal = 5.0 * 75.0 * hours
        let energyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: estimatedKcal)

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: Double(durationMinutes) * 60,
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "IronLog"]
        )

        try? await store.save(workout)
    }
}
