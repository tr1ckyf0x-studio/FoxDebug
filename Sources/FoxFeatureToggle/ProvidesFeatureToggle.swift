/// Main API protocol for checking feature flag state.
///
/// Resolution priority:
/// 1. Debug override (when set and != `.defaultValue`)
/// 2. Remote value (only when `flag.stage == .released`)
/// 3. Flag's `defaultValue`
@MainActor
public protocol ProvidesFeatureToggle: Sendable {
    /// Returns whether the flag is currently enabled.
    func isEnabled(_ flag: FeatureFlag) -> Bool

    /// Loads remote flag values from an external source.
    /// Values are keyed by `FeatureFlag.key`.
    func loadRemoteFlags(_ flags: [String: Bool]) async
}
