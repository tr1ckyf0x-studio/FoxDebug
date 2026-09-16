import Foundation
import FoxDebugStorage

/// Storage for debug override values.
///
/// Host apps may provide their own implementation (e.g. Keychain, encrypted storage).
/// The package ships `UserDefaultsFeatureToggleOverrideStore` as the default.
public protocol FeatureToggleOverrideStore: Sendable {
    /// Returns the current override for the given flag, or `nil` if none is set.
    func override(for flag: FeatureFlag) -> FeatureFlagOverride?

    /// Sets a debug override for the given flag.
    func setOverride(_ override: FeatureFlagOverride, for flag: FeatureFlag)

    /// Removes the debug override for the given flag.
    func removeOverride(for flag: FeatureFlag)
}

/// Default `FeatureToggleOverrideStore` backed by `UserDefaults`.
///
/// Uses a namespaced key prefix (`FoxFeatureToggle.override.`) to avoid
/// collisions with host app keys.
public struct UserDefaultsFeatureToggleOverrideStore: FeatureToggleOverrideStore {
    private static let keyPrefix = "FoxFeatureToggle.override."
    private let suite: UserDefaultsSuite

    /// - Parameter suiteName: The `UserDefaults` suite to store overrides in; `nil` for the standard one.
    public init(suiteName: String? = nil) {
        suite = UserDefaultsSuite(name: suiteName)
    }

    private var defaults: UserDefaults { suite.defaults }

    public func override(for flag: FeatureFlag) -> FeatureFlagOverride? {
        guard let raw = defaults.string(forKey: Self.keyPrefix + flag.key) else {
            return nil
        }
        return FeatureFlagOverride(rawValue: raw)
    }

    public func setOverride(_ override: FeatureFlagOverride, for flag: FeatureFlag) {
        defaults.set(override.rawValue, forKey: Self.keyPrefix + flag.key)
    }

    public func removeOverride(for flag: FeatureFlag) {
        defaults.removeObject(forKey: Self.keyPrefix + flag.key)
    }
}
