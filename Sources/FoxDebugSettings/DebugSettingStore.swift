import Foundation
import os

/// Storage for the values set in the debug menu. A stored value takes priority over remote and default.
///
/// Implementations must be safe to call from any thread: settings are read wherever the app needs
/// them, a networking stack included, not only on the main actor.
public protocol DebugSettingStore: Sendable {
    func rawValue(forKey key: String) -> String?
    func setRawValue(_ rawValue: String, forKey key: String)
    func removeValue(forKey key: String)
}

/// Default `DebugSettingStore` backed by `UserDefaults`, under the `FoxDebugSettings.value.` prefix.
public final class UserDefaultsDebugSettingStore: DebugSettingStore, @unchecked Sendable {
    static let keyPrefix = "FoxDebugSettings.value."
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func rawValue(forKey key: String) -> String? {
        defaults.string(forKey: Self.keyPrefix + key)
    }

    public func setRawValue(_ rawValue: String, forKey key: String) {
        defaults.set(rawValue, forKey: Self.keyPrefix + key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: Self.keyPrefix + key)
    }
}

/// `DebugSettingStore` that keeps values in memory, for tests and previews.
public final class InMemoryDebugSettingStore: DebugSettingStore {
    private let values: OSAllocatedUnfairLock<[String: String]>

    public init(values: [String: String] = [:]) {
        self.values = OSAllocatedUnfairLock(initialState: values)
    }

    public func rawValue(forKey key: String) -> String? {
        values.withLock { $0[key] }
    }

    public func setRawValue(_ rawValue: String, forKey key: String) {
        values.withLock { $0[key] = rawValue }
    }

    public func removeValue(forKey key: String) {
        values.withLock { $0[key] = nil }
    }
}
