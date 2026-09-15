#if os(iOS)
import FoxDebugMenu
import FoxFeatureToggle
import FoxFeatureToggleUI
import SwiftUI
import XCTest

/// Snapshots of the debug menu's own screens.
///
/// iOS only. The two platforms lay the same views out through different chrome — a navigation bar
/// against a window toolbar — so a shared reference image is not possible, and AppKit rendering
/// differs enough between OS releases that a macOS reference set costs more than it catches. The
/// macOS build is covered by the demo app instead.
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
#endif
