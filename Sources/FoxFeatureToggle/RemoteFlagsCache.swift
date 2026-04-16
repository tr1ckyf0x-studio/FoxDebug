import Foundation

/// Persistent cache for remote feature flag values.
///
/// Host apps may provide their own implementation (e.g. file-based, Keychain).
/// The package ships `UserDefaultsRemoteFlagsCache` as the default.
///
/// Typical usage: load cached values at startup (sync), fetch fresh values
/// in background, save them to cache — they will be applied on the NEXT launch.
public protocol RemoteFlagsCache: Sendable {
    /// Loads cached remote flags, or empty dictionary if cache is empty.
    func load() -> [String: Bool]

    /// Saves flags to cache, replacing all previous values (full replace, not merge).
    func save(_ flags: [String: Bool])

    /// Clears the cache.
    func clear()
}

/// Default `RemoteFlagsCache` backed by `UserDefaults`.
public final class UserDefaultsRemoteFlagsCache: RemoteFlagsCache, @unchecked Sendable {
    private static let storageKey = "FoxFeatureToggle.remoteCache"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> [String: Bool] {
        guard let raw = defaults.dictionary(forKey: Self.storageKey) as? [String: Bool] else {
            return [:]
        }
        return raw
    }

    public func save(_ flags: [String: Bool]) {
        defaults.set(flags, forKey: Self.storageKey)
    }

    public func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
