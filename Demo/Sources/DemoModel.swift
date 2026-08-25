import FoxDebugMenu
import FoxFeatureToggle
import FoxFeatureToggleUI
import SwiftUI

/// Wires the toggle stack the way a host app would, and keeps it alive for the whole process.
@MainActor
@Observable
final class DemoModel {
    let menuRegistry = DebugMenuRegistry()
    let provider: FeatureToggleProvider

    private let overrideStore: any FeatureToggleOverrideStore = UserDefaultsFeatureToggleOverrideStore()
    private let flagRegistry = FeatureFlagRegistry()

    init() {
        provider = FeatureToggleProvider(overrideStore: overrideStore)
        flagRegistry.register(DemoFlags.all)
        menuRegistry.register(
            FeatureToggleDebugSection(
                provider: provider,
                registry: flagRegistry,
                overrideStore: overrideStore
            )
        )
        menuRegistry.register(EnvironmentDebugSection())
    }

    var flags: [FeatureFlag] { flagRegistry.flags }
}

/// A second section, so the menu is shown doing what it is for: listing more than one thing.
struct EnvironmentDebugSection: DebugSection {
    let id = "environment"
    let title = "Environment"
    let icon = Image(systemName: "gearshape")

    var body: some View {
        List {
            LabeledContent("Bundle", value: Bundle.main.bundleIdentifier ?? "—")
            LabeledContent("Locale", value: Locale.current.identifier)
            LabeledContent("Platform", value: platformName)
        }
        .scrollContentBackground(.hidden)
        .background(Color.foxDebugBackground)
        .navigationTitle("Environment")
    }

    private var platformName: String {
        #if os(macOS)
        "macOS"
        #else
        "iOS"
        #endif
    }
}
