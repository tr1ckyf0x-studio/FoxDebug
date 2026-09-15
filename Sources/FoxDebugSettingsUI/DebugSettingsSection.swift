import FoxDebugMenu
import FoxDebugSettings
import SwiftUI

/// Pre-built `DebugSection` listing every registered debug setting.
public struct DebugSettingsSection: DebugSection {
    public let id = "foxDebugSettings"
    public let title = "Settings"
    public let icon = Image(systemName: "slider.horizontal.3")

    private let provider: DebugSettingsProvider
    private let registry: DebugSettingRegistry
    private let footer: String?

    /// - Parameter footer: Shown under the list — for example, when the app reads settings only at launch.
    public init(provider: DebugSettingsProvider, registry: DebugSettingRegistry, footer: String? = nil) {
        self.provider = provider
        self.registry = registry
        self.footer = footer
    }

    @MainActor
    public var body: some View {
        DebugSettingsListView(provider: provider, registry: registry, footer: footer)
    }
}
