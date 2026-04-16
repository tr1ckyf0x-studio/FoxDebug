import FoxDebugMenu
import FoxFeatureToggle
import SwiftUI

/// Pre-built `DebugSection` for feature toggle management.
///
/// Register this section in `DebugMenuRegistry` to add feature toggle
/// controls to the debug menu.
public struct FeatureToggleDebugSection: DebugSection {
    public let id = "foxFeatureToggles"
    public let title = "Feature Toggles"
    public let icon = Image(systemName: "flag")

    private let provider: FeatureToggleProvider
    private let registry: FeatureFlagRegistry
    private let overrideStore: any FeatureToggleOverrideStore

    public init(
        provider: FeatureToggleProvider,
        registry: FeatureFlagRegistry,
        overrideStore: any FeatureToggleOverrideStore
    ) {
        self.provider = provider
        self.registry = registry
        self.overrideStore = overrideStore
    }

    @MainActor
    public var body: some View {
        FeatureToggleListView(
            provider: provider,
            registry: registry,
            overrideStore: overrideStore
        )
    }
}
