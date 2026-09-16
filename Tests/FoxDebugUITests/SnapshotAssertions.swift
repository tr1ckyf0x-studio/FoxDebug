import SnapshotTesting
import SwiftUI
import XCTest

extension XCTestCase {
    /// Snapshots `view` in light and dark appearance, on the platform the tests run on.
    ///
    /// iOS references keep their original names; macOS ones carry the platform, so both sets live side by
    /// side in one `__Snapshots__` directory.
    @MainActor
    func assertSnapshots(
        of view: some View,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        #if os(iOS)
        // Through a `UIHostingController` rather than the bare view: navigation chrome — the bar, its large
        // title, the search field — only lays out when a view controller owns it, and a trait collection is
        // the only thing that switches appearance here. `preferredColorScheme` does not reach a detached
        // hosting controller.
        for style in [UIUserInterfaceStyle.light, .dark] {
            assertSnapshot(
                of: UIHostingController(rootView: view),
                as: .image(on: .iPhone13, traits: UITraitCollection(userInterfaceStyle: style)),
                named: style == .light ? "light" : "dark",
                file: file,
                testName: testName,
                line: line
            )
        }
        #elseif os(macOS)
        // Inside a window, which a `NavigationStack` needs to lay out. The window's own chrome — the title
        // bar and the toolbar holding the search field — is drawn outside the snapshotted view, so macOS
        // references cover content only.
        for (name, appearance) in [("macOS.light", NSAppearance.Name.aqua), ("macOS.dark", .darkAqua)] {
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(
                contentRect: CGRect(origin: .zero, size: MacSnapshot.size),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            // A window built in code releases itself on close by default, which ARC then releases again.
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: appearance)
            window.contentViewController = controller
            window.setContentSize(MacSnapshot.size)
            controller.view.layoutSubtreeIfNeeded()

            assertSnapshot(
                of: controller,
                as: .image(size: MacSnapshot.size),
                named: name,
                file: file,
                testName: testName,
                line: line
            )
            window.close()
        }
        #endif
    }
}

#if os(macOS)
private enum MacSnapshot {
    /// The debug menu's own minimum size, so a snapshot shows the layout a window opens with.
    static let size = CGSize(width: 460, height: 620)
}
#endif
