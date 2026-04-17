import SwiftUI

/// Central registry for debug menu sections.
///
/// Sections are registered at app startup. The registry drives
/// the `DebugMenuView` display.
///
/// Usage:
/// ```swift
/// let registry = DebugMenuRegistry()
/// registry.register(MyDebugSection())
/// registry.register(AnotherDebugSection())
/// ```
@MainActor
@Observable
public final class DebugMenuRegistry {
    private(set) var sections: [AnyDebugSection] = []

    public init() {}

    /// Registers a debug section for display in the menu.
    public func register<S: DebugSection>(_ section: S) {
        sections.append(AnyDebugSection(section))
    }
}
