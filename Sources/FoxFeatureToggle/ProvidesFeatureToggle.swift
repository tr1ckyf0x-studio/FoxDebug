import FoxRemoteConfig

/// Main API protocol for checking feature flag state.
///
/// Resolution priority:
/// 1. Debug override (when set and != `.defaultValue`)
/// 2. Remote value (only when `flag.stage == .released`)
/// 3. Flag's `defaultValue`
///
/// Remote values arrive through `AppliesRemoteConfig`, usually from a `RemoteConfigBootstrap`.
@MainActor
public protocol ProvidesFeatureToggle: AppliesRemoteConfig {
    /// Returns whether the flag is currently enabled.
    func isEnabled(_ flag: FeatureFlag) -> Bool
}
