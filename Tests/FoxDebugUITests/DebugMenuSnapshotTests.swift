import FoxDebugMenu
import FoxFeatureToggle
import FoxFeatureToggleUI
import SwiftUI
import XCTest

/// Snapshots of the debug menu's own screens, on iOS and macOS.
///
/// Each platform has its own references: the same views lay out through different chrome — a navigation
/// bar against a window toolbar. AppKit rendering also shifts between macOS releases, so macOS references
/// only hold on the macOS they were recorded on.
@MainActor
final class DebugMenuSnapshotTests: XCTestCase {
    func testDebugMenuWithOneSection() {
        let registry = DebugMenuRegistry()
        registry.register(StubDebugSection())

        assertSnapshots(of: DebugMenuView(registry: registry))
    }

    func testDebugMenuWithNoSections() {
        assertSnapshots(of: DebugMenuView(registry: DebugMenuRegistry()))
    }
}

private struct StubDebugSection: DebugSection {
    let id = "stub"
    let title = "Feature Toggles"
    let icon = Image(systemName: "flag")

    var body: some View {
        Text("Stub")
    }
}
