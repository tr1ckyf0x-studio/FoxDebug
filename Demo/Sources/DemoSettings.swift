import FoxDebugSettings

extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
    static let appearance = DebugSettingGroup(rawValue: "Appearance")
}

enum DemoStand: String, DebugChoiceOption {
    case development
    case staging
    case production

    var title: String { rawValue.capitalized }
}

/// Settings the demo shows off: a choice and free text that stay local, and one of each kind that also
/// accepts a remote value.
@DebugSettingContainer
enum DemoSettings {
    @DebugSetting(displayName: "Stand", group: .network, defaultValue: DemoStand.production)
    static var stand: DebugChoice<DemoStand>

    @DebugSetting(displayName: "Custom URL", group: .network, placeholder: "https://…")
    static var customURL: DebugText

    @DebugSetting(displayName: "Greeting", group: .appearance, defaultValue: "Hello", acceptsRemote: true)
    static var greeting: DebugText
}
