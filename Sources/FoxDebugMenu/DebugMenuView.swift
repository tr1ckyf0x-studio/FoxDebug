import SwiftUI

/// Universal debug menu displaying registered sections.
///
/// Each section appears as a navigation link. Supports search by title.
///
/// The layout is written once for both platforms and lets SwiftUI place things where each one
/// expects them: `.searchable` puts the field in the navigation bar on iOS and in the toolbar on
/// macOS, and a `.cancellationAction` toolbar item becomes a leading bar button on iOS and a bottom
/// sheet button on macOS. Hand-rolling either — a bordered `TextField` above the list, a `Divider`
/// and a trailing button below it — looked native on neither.
public struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    private var registry: DebugMenuRegistry
    @State private var searchText = ""

    public init(registry: DebugMenuRegistry) {
        self.registry = registry
    }

    public var body: some View {
        NavigationStack {
            List(filteredSections) { section in
                NavigationLink {
                    section.bodyView
                } label: {
                    Label {
                        Text(section.title)
                    } icon: {
                        section.icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .contentMargins(.top, Metrics.listTopMargin, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(Color.foxDebugBackground)
            .toolbarBackground(Color.foxDebugBackground, for: .automatic)
            .navigationTitle("Debug Menu")
            .searchable(text: $searchText, prompt: Text("Search sections"))
            .overlay {
                if filteredSections.isEmpty {
                    emptyState
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: Metrics.macMinWidth, minHeight: Metrics.macMinHeight)
        #endif
    }

    @ViewBuilder
    private var emptyState: some View {
        if searchText.isEmpty {
            ContentUnavailableView(
                "No Debug Sections",
                systemImage: "wrench.and.screwdriver",
                description: Text("Register one with DebugMenuRegistry.register(_:).")
            )
        } else {
            ContentUnavailableView.search(text: searchText)
        }
    }

    private var filteredSections: [AnyDebugSection] {
        if searchText.isEmpty {
            return registry.sections
        }
        return registry.sections.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private enum Metrics {
        static let iconSize: CGFloat = 22

        /// A list whose first section has no header sits flush against the search field, which
        /// reads as a mistake. This is the gap a grouped list normally leaves above its first group.
        static let listTopMargin: CGFloat = 16
        static let macMinWidth: CGFloat = 460
        static let macMinHeight: CGFloat = 520
    }
}
