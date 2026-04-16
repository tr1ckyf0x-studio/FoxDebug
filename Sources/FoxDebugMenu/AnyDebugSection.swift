import SwiftUI

/// Type-erased wrapper for `DebugSection`.
///
/// Created internally by `DebugMenuRegistry.register(_:)`.
/// Not exposed publicly — consumers only work with the `DebugSection` protocol.
struct AnyDebugSection: Identifiable {
    let id: String
    let title: String
    let icon: Image
    private let _body: @MainActor () -> AnyView

    init<S: DebugSection>(_ section: S) {
        self.id = section.id
        self.title = section.title
        self.icon = section.icon
        self._body = { AnyView(section.body) }
    }

    @MainActor
    var bodyView: AnyView { _body() }
}
