#if os(iOS)
import FoxDebugSettings
@testable import FoxDebugSettingsUI
import FoxRemoteConfig
import SwiftUI
import XCTest

/// Snapshots of the settings screen: every value at its default, values set locally and remotely
/// (which shows both badges and the reset button), and nothing registered.
@MainActor
final class DebugSettingsListSnapshotTests: XCTestCase {
    private enum Stand: String, DebugChoiceOption {
        case development
        case production

        var title: String { rawValue.capitalized }
    }

    private let stand = DebugChoice(
        key: "stand",
        displayName: "Stand",
        group: DebugSettingGroup(rawValue: "Network"),
        defaultValue: Stand.production
    )
    private let customURL = DebugText(
        key: "customURL",
        displayName: "Custom URL",
        group: DebugSettingGroup(rawValue: "Network"),
        placeholder: "https://…"
    )
    private let greeting = DebugText(
        key: "greeting",
        displayName: "Greeting",
        group: DebugSettingGroup(rawValue: "Copy"),
        defaultValue: "Hello",
        acceptsRemote: true
    )

    func testSettingsAtDefaults() {
        assertSnapshots(of: makeView(footer: "Applied on next launch."))
    }

    func testLocalAndRemoteValues() {
        assertSnapshots(
            of: makeView(
                local: ["stand": "development", "customURL": "https://dev.example.com"],
                remote: ["greeting": "Hi from remote"]
            )
        )
    }

    func testNoSettingsRegistered() {
        assertSnapshots(of: makeView(settings: []))
    }

    private func makeView(
        settings: [DebugSettingDescriptor]? = nil,
        local: [String: String] = [:],
        remote: [String: String] = [:],
        footer: String? = nil
    ) -> some View {
        let provider = DebugSettingsProvider(store: InMemoryDebugSettingStore(values: local))
        provider.applyRemoteConfig(RemoteConfig(settings: remote))
        let registry = DebugSettingRegistry()
        registry.register(settings ?? [stand.descriptor, customURL.descriptor, greeting.descriptor])

        return NavigationStack {
            DebugSettingsListView(provider: provider, registry: registry, footer: footer)
        }
    }
}
#endif
