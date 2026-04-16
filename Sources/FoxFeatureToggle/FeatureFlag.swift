/// Definition of a single feature flag.
///
/// Instances are created via the `@FeatureToggle` macro or manually.
/// Each flag has a unique key, display metadata, lifecycle stage,
/// and a default value.
public struct FeatureFlag: Hashable, Sendable, Identifiable {
    /// Unique identifier derived from the property name.
    public let key: String

    /// Human-readable name shown in the debug menu.
    public let displayName: String

    /// Grouping for the debug menu UI.
    public let group: FeatureFlagGroup

    /// Lifecycle stage controlling remote value behavior.
    public let stage: FeatureFlagStage

    /// Default value when no override or remote value is set.
    public let defaultValue: Bool

    public var id: String { key }

    public init(
        key: String,
        displayName: String,
        group: FeatureFlagGroup,
        stage: FeatureFlagStage,
        defaultValue: Bool = false
    ) {
        self.key = key
        self.displayName = displayName
        self.group = group
        self.stage = stage
        self.defaultValue = defaultValue
    }
}
