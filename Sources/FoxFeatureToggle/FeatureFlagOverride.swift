/// Debug override state for a feature flag.
///
/// Three-state control: no override, force enabled, or force disabled.
public enum FeatureFlagOverride: String, Sendable, CaseIterable {
    /// No override applied — use normal resolution chain (remote → default).
    case defaultValue

    /// Force the flag to be enabled regardless of remote or default values.
    case forceEnabled

    /// Force the flag to be disabled regardless of remote or default values.
    case forceDisabled
}
