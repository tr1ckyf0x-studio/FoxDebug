import FoxDebugMenu
import FoxDebugSettings
import SwiftUI

/// Displays registered debug settings grouped by `DebugSettingGroup`, in registration order, with search
/// by display name.
struct DebugSettingsListView: View {
    let provider: DebugSettingsProvider
    var registry: DebugSettingRegistry
    let footer: String?

    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(groupedSettings, id: \.group) { group in
                Section(group.group.rawValue) {
                    ForEach(group.settings) { setting in
                        DebugSettingRowView(setting: setting, provider: provider)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            if let footer, !groupedSettings.isEmpty {
                Section {} footer: {
                    Text(footer)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.foxDebugBackground)
        .toolbarBackground(Color.foxDebugBackground, for: .automatic)
        .navigationTitle("Settings")
        .searchable(text: $searchText, prompt: Text("Search settings"))
        .overlay {
            if groupedSettings.isEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if searchText.isEmpty {
            ContentUnavailableView(
                "No Settings",
                systemImage: "slider.horizontal.3",
                description: Text("Register them with DebugSettingRegistry.register(_:).")
            )
        } else {
            ContentUnavailableView.search(text: searchText)
        }
    }

    private var groupedSettings: [(group: DebugSettingGroup, settings: [DebugSettingDescriptor])] {
        let settings = searchText.isEmpty
            ? registry.settings
            : registry.settings.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        return registry.groups.compactMap { group in
            let members = settings.filter { $0.group == group }
            return members.isEmpty ? nil : (group, members)
        }
    }
}
