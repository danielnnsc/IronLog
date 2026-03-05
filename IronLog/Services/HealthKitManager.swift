import HealthKit
import Foundation

/// Writes completed strength training workouts to Apple Health and reads body mass.
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

    private var typesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        try? await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    // MARK: - Read Body Mass

    /// Returns the most recent body mass sample from Health in pounds, or nil if unavailable.
    func fetchBodyMassLbs() async -> Double? {
        guard isAvailable,
              let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: .pound()))
            }
            store.execute(query)
        }
    }

    // MARK: - Save Workout

    /// Saves a traditional strength training workout to Apple Health.
    /// - Parameters:
    ///   - startDate:      When the workout began.
    ///   - durationMinutes: Total workout duration.
    ///   - bodyWeightLbs:  User's body weight in pounds, used to estimate calories.
    func saveWorkout(startDate: Date, durationMinutes: Int, bodyWeightLbs: Double) async {
        guard isAvailable else { return }

        await requestAuthorization()

        let endDate = startDate.addingTimeInterval(Double(durationMinutes) * 60)

        // Active calories: 5.0 METs × body weight (kg) × hours
        let bodyWeightKg = bodyWeightLbs * 0.453592
        let hours = max(Double(durationMinutes) / 60.0, 1.0 / 60.0)
        let estimatedKcal = 5.0 * bodyWeightKg * hours
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
