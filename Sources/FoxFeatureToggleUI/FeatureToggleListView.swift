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
struct FeatureToggleListView: View {
    var provider: FeatureToggleProvider
    var registry: FeatureFlagRegistry
    let overrideStore: any FeatureToggleOverrideStore

    @State private var searchText = ""
    @State private var filter: FeatureToggleFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search flags...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 8)

            List {
                Picker("Filter", selection: $filter) {
                    ForEach(FeatureToggleFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                ForEach(groupedFlags, id: \.group) { group in
                    Section(group.group.rawValue) {
                        ForEach(group.flags) { flag in
                            FeatureToggleRowView(
                                flag: flag,
                                provider: provider,
                                overrideStore: overrideStore
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Feature Toggles")
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
}
