#if os(iOS)
import SnapshotTesting
import SwiftUI
import XCTest

extension XCTestCase {
    /// Snapshots `view` in light and dark appearance.
    ///
    /// Goes through a `UIHostingController` rather than the bare view: navigation chrome — the bar, its
    /// large title, the search field — only lays out when a view controller owns it, and a trait
    /// collection is the only thing that actually switches appearance here. `preferredColorScheme` does
    /// not reach a detached hosting controller.
    @MainActor
    func assertSnapshots(
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
#endif
