import FoxDebugMenu
import SwiftUI

/// One app for both platforms. Everything below is shared; only how the menu is opened differs, and
/// that lives in ``DemoRootView``.
@main
struct DemoApp: App {
    @State private var model = DemoModel()

    var body: some Scene {
        WindowGroup {
            DemoRootView()
                .environment(model)
        }
        #if os(macOS)
        .defaultSize(width: 520, height: 640)
        #endif
    }
}
