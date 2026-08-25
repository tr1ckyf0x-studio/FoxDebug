#if os(iOS)
import SwiftUI
import UIKit

/// Reports a device shake to SwiftUI.
///
/// The gesture is caught on `UIWindow` rather than on a view controller: a debug menu should open
/// from wherever the app happens to be, and the window is the one object that is always there.
extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("FoxDebugDemo.deviceDidShake")
}

extension View {
    func onShakeGesture(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            action()
        }
    }
}
#endif
