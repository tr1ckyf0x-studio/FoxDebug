import Foundation

/// Persistent cache for remote values.
///
/// Host apps may provide their own implementation (file-based, Keychain). The package ships
/// `UserDefaultsRemoteConfigCache` as the default.
public protocol RemoteConfigCache: Sendable {
    /// Loads the cached config, or `.empty` if nothing is cached or the cache cannot be read.
    func load() -> RemoteConfig

    /// Saves the config, replacing everything cached before (full replace, not merge).
    func save(_ config: RemoteConfig)

    /// Clears the cache.
    func clear()
}

/// Default `RemoteConfigCache` backed by `UserDefaults`, storing the config as JSON.
public final class UserDefaultsRemoteConfigCache: RemoteConfigCache, @unchecked Sendable {
    static let storageKey = "FoxRemoteConfig.cache"
    /// Where 2.x `UserDefaultsRemoteFlagsCache` kept flags. Read until the first save, so updating the
    /// package does not drop remote flags — a kill switch among them — for a session.
    static let legacyFlagsKey = "FoxFeatureToggle.remoteCache"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> RemoteConfig {
        if let data = defaults.data(forKey: Self.storageKey) {
            return (try? JSONDecoder().decode(RemoteConfig.self, from: data)) ?? .empty
        }
        if let legacyFlags = defaults.dictionary(forKey: Self.legacyFlagsKey) as? [String: Bool] {
            return RemoteConfig(flags: legacyFlags)
        }
        return .empty
    }

    public func save(_ config: RemoteConfig) {
        guard let data = try? JSONEncoder().encode(config) else {
            return
        }
        defaults.set(data, forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.legacyFlagsKey)
    }

    public func clear() {
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.legacyFlagsKey)
    }
}
