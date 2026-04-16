/// Lifecycle stage of a feature flag.
///
/// Determines whether remote values are applied.
public enum FeatureFlagStage: String, Sendable {
    /// Feature is in active development.
    /// Remote values are **ignored** — only debug override or default value apply.
    /// This prevents unfinished features from activating on old builds
    /// when the remote flag is later enabled.
    case development

    /// Feature is released and ready for remote configuration.
    /// Remote values are **applied** (unless debug override is set).
    case released
}
