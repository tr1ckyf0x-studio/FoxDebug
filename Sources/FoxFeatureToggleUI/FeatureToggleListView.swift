import FoxDebugMenu
import FoxFeatureToggle
import SwiftUI

/// Filter mode for the flag list.
enum FeatureToggleFilter: String, CaseIterable {
    case all = "All"
    case overridden = "Overridden"
}

/// Displays all registered feature flags grouped by `FeatureFlagGroup`.
///
/// Supports search by display name and filtering by override status.
///
/// The filter is pinned above the list through `safeAreaInset` rather than being the list's first
/// row: it applies to everything below it, so it should not scroll away with the content it filters.
struct FeatureToggleListView: View {
    var provider: FeatureToggleProvider
    var registry: FeatureFlagRegistry
    let overrideStore: any FeatureToggleOverrideStore

    @State private var searchText = ""
    @State private var filter: FeatureToggleFilter = .all

    var body: some View {
        List {
            ForEach(groupedFlags, id: \.group) { group in
                Section(group.group.rawValue) {
                    ForEach(group.flags) { flag in
                        FeatureToggleRowView(
                            flag: flag,
                            provider: provider,
                            overrideStore: overrideStore
                        )
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.foxDebugBackground)
        .toolbarBackground(Color.foxDebugBackground, for: .automatic)
        .navigationTitle("Feature Toggles")
        .searchable(text: $searchText, prompt: Text("Search flags"))
        .safeAreaInset(edge: .top, spacing: 0) {
            filterPicker
        }
        .overlay {
            if groupedFlags.isEmpty {
                emptyState
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(FeatureToggleFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal)
        .padding(.vertical, Metrics.filterVerticalPadding)
        .background(Color.foxDebugBackground)
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filter == .overridden {
            ContentUnavailableView(
                "No Overrides",
                systemImage: "flag.slash",
                description: Text("Every flag is at its default value.")
            )
        } else {
            ContentUnavailableView(
                "No Feature Flags",
                systemImage: "flag",
                description: Text("Register them with FeatureFlagRegistry.register(_:).")
            )
        }
    }

    private var filteredFlags: [FeatureFlag] {
        var flags = registry.flags

        if !searchText.isEmpty {
            flags = flags.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        if filter == .overridden {
            flags = flags.filter { overrideStore.override(for: $0) != nil }
        }

        return flags
    }

    private var groupedFlags: [(group: FeatureFlagGroup, flags: [FeatureFlag])] {
        let grouped = Dictionary(grouping: filteredFlags, by: \.group)
        return grouped
            .map { (group: $0.key, flags: $0.value) }
            .sorted { $0.group.rawValue < $1.group.rawValue }
    }

    private enum Metrics {
        static let filterVerticalPadding: CGFloat = 8
    }
}
