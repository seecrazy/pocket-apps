import Foundation
import HealthKit

protocol MindfulMinutesWriting {
    func requestAuthorization() async -> Bool
    func save(seconds: Double, startedAt: Date, endedAt: Date) async -> Bool
}

final class HealthKitMindfulMinutesWriter: MindfulMinutesWriting {
    private let store = HKHealthStore()
    private var hasRequestedAuthorization = false

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard Self.isAvailable, let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return false }

        do {
            try await store.requestAuthorization(toShare: [mindfulType], read: [])
            hasRequestedAuthorization = true
            return true
        } catch {
            return false
        }
    }

    func save(seconds: Double, startedAt: Date, endedAt: Date) async -> Bool {
        guard Self.isAvailable, seconds > 0,
              let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return false }

        if !hasRequestedAuthorization {
            let authorized = await requestAuthorization()
            guard authorized else { return false }
        }

        let sample = HKCategorySample(
            type: mindfulType,
            value: 0,
            start: startedAt,
            end: endedAt
        )

        do {
            try await store.save(sample)
            return true
        } catch {
            return false
        }
    }
}
