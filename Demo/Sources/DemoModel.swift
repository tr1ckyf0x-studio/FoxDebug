import FoxDebugMenu
import FoxDebugSettings
import FoxDebugSettingsUI
import FoxFeatureToggle
import FoxFeatureToggleUI
import FoxRemoteConfig
import SwiftUI

/// Wires flags, settings and remote config the way a host app would, and keeps them alive for the
/// whole process.
@MainActor
@Observable
final class DemoModel {
    let menuRegistry = DebugMenuRegistry()
    let provider: FeatureToggleProvider
    let settingsProvider = DebugSettingsProvider()

    private let overrideStore: any FeatureToggleOverrideStore = UserDefaultsFeatureToggleOverrideStore()
    private let flagRegistry = FeatureFlagRegistry()
    private let settingsRegistry = DebugSettingRegistry()

    init() {
        provider = FeatureToggleProvider(overrideStore: overrideStore)
        flagRegistry.register(DemoFlags.all)
        settingsRegistry.register(DemoSettings.all)

        RemoteConfigBootstrap(
            fetcher: DemoRemoteConfigFetcher(),
            cache: UserDefaultsRemoteConfigCache(),
            consumers: [provider, settingsProvider]
        )
        .run()

        menuRegistry.register(
            FeatureToggleDebugSection(
                provider: provider,
                registry: flagRegistry,
                overrideStore: overrideStore
            )
        )
        menuRegistry.register(DebugSettingsSection(provider: settingsProvider, registry: settingsRegistry))
        menuRegistry.register(EnvironmentDebugSection())
    }

    var flags: [FeatureFlag] { flagRegistry.flags }
    var settings: [DebugSettingDescriptor] { settingsRegistry.settings }
}

/// Stands in for a real backend. The bootstrap caches what it returns, so its values show up from the
/// second launch on — which is the point the demo makes.
struct DemoRemoteConfigFetcher: RemoteConfigFetcher {
    func fetch() async throws -> RemoteConfig {
        RemoteConfig(
            flags: ["concurrentScan": false],
            settings: ["greeting": "Hello from remote", "stand": "development"]
        )
    }
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
