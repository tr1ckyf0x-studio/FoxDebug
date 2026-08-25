#if os(iOS)
import FoxDebugMenu
import FoxFeatureToggle
import FoxFeatureToggleUI
import SnapshotTesting
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

    /// Snapshots through a `UIHostingController` rather than the bare view: navigation chrome — the
    /// bar, its large title, the search field — only lays out when a view controller owns it, and a
    /// trait collection is the only thing that actually switches appearance here.
    /// `preferredColorScheme` does not reach a detached hosting controller.
    private func assertSnapshots(
        of view: some View,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            assertSnapshot(
                of: UIHostingController(rootView: view),
                as: .image(
                    on: .iPhone13,
                    traits: UITraitCollection(userInterfaceStyle: style)
                ),
                named: style == .light ? "light" : "dark",
                file: file,
                testName: testName,
                line: line
            )
        }
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
