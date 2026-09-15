import FoxDebugSettings

extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
    static let logging = DebugSettingGroup(rawValue: "Logging")
}

enum Stand: String, DebugChoiceOption {
    case development
    case staging
    case production

    var title: String { rawValue.capitalized }
}

enum LogLevel: String, DebugChoiceOption {
    case debug
    case error
}

/// Declared through the macros, as a host app would, so the tests exercise their real expansion.
@DebugSettingContainer
enum TestSettings {
    @DebugSetting(displayName: "Stand", group: .network, defaultValue: Stand.production)
    static var stand: DebugChoice<Stand>

    @DebugSetting(displayName: "Custom URL", group: .network, placeholder: "https://…")
    static var customURL: DebugText

    @DebugSetting(displayName: "Log level", group: .logging, defaultValue: LogLevel.error, acceptsRemote: true)
    static var logLevel: DebugChoice<LogLevel>

    @DebugSetting(displayName: "Greeting", group: .logging, defaultValue: "hello", acceptsRemote: true)
    static var greeting: DebugText

    static var notASetting: Int { 0 }
}
