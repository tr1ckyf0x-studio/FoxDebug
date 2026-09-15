/// Grouping identifier for debug settings.
///
/// A struct rather than an enum so host apps can add their own groups:
/// ```swift
/// extension DebugSettingGroup {
///     static let network = DebugSettingGroup(rawValue: "Network")
/// }
/// ```
public struct DebugSettingGroup: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
