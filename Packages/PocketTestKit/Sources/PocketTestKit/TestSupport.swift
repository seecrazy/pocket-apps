import Foundation
import PocketCore

public final class FixedDateProvider: DateProvider {
    private let date: Date

    public init(date: Date) {
        self.date = date
    }

    public func now() -> Date {
        date
    }
}

public final class InMemoryKeyValueStore: KeyValueStore {
    private var values: [String: Any] = [:]

    public init() {}

    public func bool(forKey key: String) -> Bool {
        values[key] as? Bool ?? false
    }

    public func string(forKey key: String) -> String? {
        values[key] as? String
    }

    public func integer(forKey key: String) -> Int {
        values[key] as? Int ?? 0
    }

    public func set(_ value: Bool, forKey key: String) {
        values[key] = value
    }

    public func set(_ value: String?, forKey key: String) {
        values[key] = value
    }

    public func set(_ value: Int, forKey key: String) {
        values[key] = value
    }

    public func removeObject(forKey key: String) {
        values.removeValue(forKey: key)
    }
}
