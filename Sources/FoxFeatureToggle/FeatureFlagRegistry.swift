import SwiftUI

/// Central registry collecting all feature flags for debug menu display.
///
/// Flags are registered at app startup from `@FeatureFlagContainer` enums.
@MainActor
@Observable
public final class FeatureFlagRegistry {
    /// All registered feature flags.
    public private(set) var flags: [FeatureFlag] = []

    public init() {}

    /// Registers an array of flags (typically from a `@FeatureFlagContainer`'s `all` property).
    public func register(_ flags: [FeatureFlag]) {
        self.flags.append(contentsOf: flags)
    }

    /// Returns all unique groups across registered flags.
    public var groups: [FeatureFlagGroup] {
        Array(Set(flags.map(\.group)))
    }
}
