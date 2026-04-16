/// Transforms a `static var` property into a computed property returning a `FeatureFlag`.
///
/// The property name becomes the flag's `key`.
///
/// Usage:
/// ```swift
/// @FeatureToggle(displayName: "Concurrent Scan", group: .diskAnalyzer, stage: .development)
/// static var concurrentScan: FeatureFlag
/// ```
///
/// - Parameters:
///   - displayName: Human-readable name shown in the debug menu.
///   - group: Grouping for the debug menu.
///   - stage: Lifecycle stage (`.development` or `.released`).
///   - defaultValue: Default value when no override or remote value applies. Defaults to `false`.
///
/// - Important: Must be applied to `static var` (not `static let`).
@attached(accessor)
public macro FeatureToggle(
    displayName: String,
    group: FeatureFlagGroup,
    stage: FeatureFlagStage,
    defaultValue: Bool = false
) = #externalMacro(module: "FoxFeatureToggleMacros", type: "FeatureToggleMacro")

/// Generates a `static let all: [FeatureFlag]` property collecting all
/// `@FeatureToggle`-annotated members in the type.
///
/// Usage:
/// ```swift
/// @FeatureFlagContainer
/// enum DiskAnalyzerFlags {
///     @FeatureToggle(displayName: "Concurrent Scan", group: .diskAnalyzer, stage: .development)
///     static var concurrentScan: FeatureFlag
/// }
/// // Generated: static let all: [FeatureFlag] = [concurrentScan]
/// ```
@attached(member, names: named(all))
public macro FeatureFlagContainer() = #externalMacro(module: "FoxFeatureToggleMacros", type: "FeatureFlagContainerMacro")
