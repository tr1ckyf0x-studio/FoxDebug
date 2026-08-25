import FoxFeatureToggle

extension FeatureFlagGroup {
    static let core = FeatureFlagGroup(rawValue: "Core")
    static let experiments = FeatureFlagGroup(rawValue: "Experiments")
}

/// Flags the demo shows off. Deliberately spread across both groups and both stages so the menu has
/// something to group, filter and badge.
@FeatureFlagContainer
enum DemoFlags {
    @FeatureToggle(
        displayName: "Concurrent scan",
        group: .core,
        stage: .released,
        defaultValue: true
    )
    static var concurrentScan: FeatureFlag

    @FeatureToggle(
        displayName: "Verbose logging",
        group: .core,
        stage: .development
    )
    static var verboseLogging: FeatureFlag

    @FeatureToggle(
        displayName: "New onboarding",
        group: .experiments,
        stage: .development
    )
    static var newOnboarding: FeatureFlag
}
