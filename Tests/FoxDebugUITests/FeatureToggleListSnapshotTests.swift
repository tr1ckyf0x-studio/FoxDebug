#if os(iOS)
import FoxFeatureToggle
@testable import FoxFeatureToggleUI
import SnapshotTesting
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

    /// Snapshots through a `UIHostingController` rather than the bare view: navigation chrome — the
    /// bar, its large title, the search field — only lays out when a view controller owns it, and a
    /// trait collection is the only thing that actually switches appearance here.
    /// `preferredColorScheme` does not reach a detached hosting controller.
    private func assertSnapshots(
        of view: some View,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            assertSnapshot(
                of: UIHostingController(rootView: view),
                as: .image(
                    on: .iPhone13,
                    traits: UITraitCollection(userInterfaceStyle: style)
                ),
                named: style == .light ? "light" : "dark",
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

/// Keeps overrides in memory so a snapshot never depends on what a previous run left in
/// `UserDefaults`.
private final class InMemoryOverrideStore: FeatureToggleOverrideStore, @unchecked Sendable {
    private var overrides: [String: FeatureFlagOverride]

    init(overrides: [String: FeatureFlagOverride]) {
        self.overrides = overrides
    }

    func override(for flag: FeatureFlag) -> FeatureFlagOverride? {
        overrides[flag.key]
    }

    func setOverride(_ override: FeatureFlagOverride, for flag: FeatureFlag) {
        overrides[flag.key] = override
    }

    func removeOverride(for flag: FeatureFlag) {
        overrides[flag.key] = nil
    }
}
#endif
