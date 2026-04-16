import SwiftUI

/// Universal debug menu displaying registered sections.
///
/// Each section appears as a navigation link. Supports search by title.
public struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registry: DebugMenuRegistry
    @State private var searchText = ""

    public init(registry: DebugMenuRegistry) {
        self.registry = registry
    }

    public var body: some View {
        VStack(spacing: 0) {
            NavigationStack {
                VStack(spacing: 0) {
                    TextField("Search sections...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    List(filteredSections) { section in
                        NavigationLink {
                            section.bodyView
                        } label: {
                            HStack(spacing: 14) {
                                section.icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(Color.accentColor)
                                Text(section.title)
                                    .font(.title3)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .navigationTitle("Debug Menu")
            }

            Divider()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
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
}
