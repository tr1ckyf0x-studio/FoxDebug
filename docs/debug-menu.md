# Debug menu

`DebugMenuView` is a searchable list of **sections**. Each section is a screen of its own; the menu
only lists them and navigates into one. FoxDebug ships two sections — feature toggles and settings —
and anything else is a section the app writes.

## Opening the menu

`DebugMenuView` brings its own `NavigationStack` and a **Close** button, so present it modally rather
than pushing it:

```swift
.sheet(isPresented: $isDebugMenuPresented) {
    DebugMenuView(registry: debugMenuRegistry)
}
```

How it gets opened is up to the app. A debug menu should cost no screen space, so the usual trigger
on iOS is a shake. The package deliberately does not ship one — how a gesture is caught is app
policy — but the demo's version is short enough to copy:

```swift
#if os(iOS)
import SwiftUI
import UIKit

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension View {
    func onShakeGesture(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in action() }
    }
}
#endif
```

In the Simulator a shake is **⌃⌘Z**. While a text field is first responder the shake goes to the
field instead (it offers Undo), so dismiss the keyboard first. On macOS use a menu command or a
keyboard shortcut, as `Demo/Sources/DemoRootView.swift` does with ⌘⇧D.

## Writing a section

Conform to `DebugSection`. The `id` must be unique across registered sections; `title` is what the
menu lists and searches.

```swift
import FoxDebugMenu
import SwiftUI

struct SessionDebugSection: DebugSection {
    let id = "session"
    let title = "Session"
    let icon = Image(systemName: "person.badge.key")

    let session: SessionStore

    var body: some View {
        SessionDebugView(session: session)
    }
}

private struct SessionDebugView: View {
    let session: SessionStore

    var body: some View {
        List {
            LabeledContent("User", value: session.userID ?? "—")
            Button("Expire access token", role: .destructive) {
                session.expireAccessToken()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.foxDebugBackground)
        .navigationTitle("Session")
    }
}

debugMenuRegistry.register(SessionDebugSection(session: session))
```

Put the screen in its own view rather than building it inline in `body`: `@State`, `@Environment`
and the rest only work inside a `View`, and `DebugSection` is not one.

Sections are listed in registration order. Register everything once, at launch — the registry has no
way to remove a section.

## Matching the menu's look

Two public pieces keep a custom section consistent with the built-in ones:

- `Color.foxDebugBackground` — the grouped background every FoxDebug screen uses. Pair it with
  `.scrollContentBackground(.hidden)` on a `List`.
- `DebugBadge` — the small uppercase tag the built-in rows show beside a title:

  ```swift
  HStack {
      Text("Payments sandbox")
      DebugBadge("STAGING", color: .orange)
  }
  ```

  The built-in sections use `DEV` in orange for an unreleased flag, `LOCAL` in blue for a value set in
  the menu and `REMOTE` in purple for a value delivered by a backend. Reusing those colours for those
  meanings keeps the menu readable.
