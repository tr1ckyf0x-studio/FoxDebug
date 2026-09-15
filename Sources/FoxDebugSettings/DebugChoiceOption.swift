/// A value a `DebugChoice` picks from. Every case appears in the picker, in `allCases` order.
///
/// ```swift
/// enum Stand: String, DebugChoiceOption {
///     case development, production
/// }
/// ```
public protocol DebugChoiceOption: RawRepresentable, CaseIterable, Sendable where RawValue == String {
    /// Title shown in the picker. Defaults to `rawValue`.
    var title: String { get }
}

public extension DebugChoiceOption {
    var title: String { rawValue }
}
