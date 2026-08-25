import FoxDebugMenu
import FoxFeatureToggle
import SwiftUI

/// Shows what the host app sees: the current value of every flag, and a way into the menu.
///
/// On iOS the menu opens on a shake, which is what a real app does — a debug menu should cost no
/// screen real estate. macOS has no shake, so there it is a toolbar button and ⌘⇧D.
struct DemoRootView: View {
    @Environment(DemoModel.self) private var model
    @State private var isMenuPresented = false

    var body: some View {
        NavigationStack {
            List(model.flags) { flag in
                LabeledContent(flag.displayName) {
                    Text(model.provider.isEnabled(flag) ? "on" : "off")
                        .foregroundStyle(model.provider.isEnabled(flag) ? Color.green : .secondary)
                        .monospaced()
                }
            }
            .navigationTitle("FoxDebug Demo")
            .safeAreaInset(edge: .bottom) {
                hint
            }
            .toolbar {
                ToolbarItem {
                    Button("Debug Menu", systemImage: "ladybug") {
                        isMenuPresented = true
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                }
            }
        }
        .sheet(isPresented: $isMenuPresented) {
            DebugMenuView(registry: model.menuRegistry)
        }
        #if os(iOS)
        .onShakeGesture {
            isMenuPresented = true
        }
        #endif
    }

    private var hint: some View {
        Text(hintText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.bar)
    }

    private var hintText: String {
        #if os(iOS)
        "Shake the device (⌃⌘Z in the simulator) or use the toolbar button."
        #else
        "Press ⌘⇧D or use the toolbar button."
        #endif
    }
}
