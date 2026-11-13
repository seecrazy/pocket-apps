import Foundation

public protocol KeyValueStore {
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func integer(forKey key: String) -> Int
    func set(_ value: Bool, forKey key: String)
    func set(_ value: String?, forKey key: String)
    func set(_ value: Int, forKey key: String)
    func removeObject(forKey key: String)
}

public struct UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
