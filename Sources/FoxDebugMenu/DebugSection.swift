import SwiftUI

/// Protocol for registerable debug menu sections.
///
/// Conforming types provide a title, icon, and SwiftUI body
/// that is displayed when the section is selected in the debug menu.
///
/// Usage:
/// ```swift
/// struct MyDebugSection: DebugSection {
///     let id = "mySection"
///     let title = "My Section"
///     let icon = Image(systemName: "wrench")
///
///     var body: some View {
///         Text("Debug content here")
///     }
/// }
/// ```
public protocol DebugSection: Identifiable {
    associatedtype Body: View

    /// Unique identifier for this section.
    var id: String { get }

    /// Display title shown in the debug menu list.
    var title: String { get }

    /// Icon shown next to the title.
    var icon: Image { get }

    /// The SwiftUI content displayed when this section is selected.
    @MainActor @ViewBuilder var body: Body { get }
}
