#if os(iOS)
import FoxFeatureToggle
import os
@testable import FoxFeatureToggleUI
import SwiftUI
import XCTest

/// Snapshots of the feature-toggle screen in the states it actually reaches: flags at their
/// defaults, a flag overridden, and the empty result of filtering to overrides when there are none.
@MainActor
final class FeatureToggleListSnapshotTests: XCTestCase {
    private let flags = [
        FeatureFlag(
            key: "swiftUIFlow",
            displayName: "SwiftUI flow",
            group: FeatureFlagGroup(rawValue: "Flow"),
            stage: .development
        ),
        FeatureFlag(
            key: "concurrentScan",
            displayName: "Concurrent scan",
            group: FeatureFlagGroup(rawValue: "Core"),
            stage: .released,
            defaultValue: true
        )
    ]

    func testFlagsAtDefaults() {
        assertSnapshots(of: makeView(overrides: [:]))
    }

    func testFlagOverridden() {
        assertSnapshots(of: makeView(overrides: ["swiftUIFlow": .forceEnabled]))
    }

    func testNoFlagsRegistered() {
        assertSnapshots(of: makeView(flags: [], overrides: [:]))
    }

    private func makeView(
        flags: [FeatureFlag]? = nil,
        overrides: [String: FeatureFlagOverride]
    ) -> some View {
        let store = InMemoryOverrideStore(overrides: overrides)
        let registry = FeatureFlagRegistry()
        registry.register(flags ?? self.flags)

        return NavigationStack {
            FeatureToggleListView(
                provider: FeatureToggleProvider(overrideStore: store),
                registry: registry,
                overrideStore: store
            )
        }
    }
}

/// Keeps overrides in memory so a snapshot never depends on what a previous run left in
/// `UserDefaults`.
private final class InMemoryOverrideStore: FeatureToggleOverrideStore {
    private let overrides: OSAllocatedUnfairLock<[String: FeatureFlagOverride]>

    init(overrides: [String: FeatureFlagOverride]) {
        self.overrides = OSAllocatedUnfairLock(initialState: overrides)
    }

    func override(for flag: FeatureFlag) -> FeatureFlagOverride? {
        overrides.withLock { $0[flag.key] }
    }

    func setOverride(_ override: FeatureFlagOverride, for flag: FeatureFlag) {
        overrides.withLock { $0[flag.key] = override }
    }

    func removeOverride(for flag: FeatureFlag) {
        overrides.withLock { $0[flag.key] = nil }
    }
}
#endif
