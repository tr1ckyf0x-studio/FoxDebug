import SwiftUI

public extension Color {
    /// The one background the debug menu paints.
    ///
    /// Lists inside the menu hide their own background and use this instead, and so does the
    /// navigation bar. Without that the bar's material tints a slightly different grey from the
    /// list's, and the seam between them is plainly visible at rest.
    ///
    /// Public because a custom `DebugSection` needs the same colour to sit flush with the rest of
    /// the menu.
    static var foxDebugBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
}
