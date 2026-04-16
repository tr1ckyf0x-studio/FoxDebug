import FoxFeatureToggle
import SwiftUI

/// Displays a single feature flag with a 3-state override picker.
struct FeatureToggleRowView: View {
    let flag: FeatureFlag
    @ObservedObject var provider: FeatureToggleProvider
    let overrideStore: any FeatureToggleOverrideStore

    @State private var currentOverride: FeatureFlagOverride

    init(flag: FeatureFlag, provider: FeatureToggleProvider, overrideStore: any FeatureToggleOverrideStore) {
        self.flag = flag
        self.provider = provider
        self.overrideStore = overrideStore
        self._currentOverride = State(initialValue: overrideStore.override(for: flag) ?? .defaultValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flag.displayName)
                    .font(.body)

                if flag.stage == .development {
                    Text("DEV")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }

                Spacer()

                Circle()
                    .fill(provider.isEnabled(flag) ? Color.green : Color.red.opacity(0.5))
                    .frame(width: 8, height: 8)
            }

            Picker("Override", selection: $currentOverride) {
                Text("Default").tag(FeatureFlagOverride.defaultValue)
                Text("On").tag(FeatureFlagOverride.forceEnabled)
                Text("Off").tag(FeatureFlagOverride.forceDisabled)
            }
            .pickerStyle(.segmented)
            .onChange(of: currentOverride) { _, newValue in
                if newValue == .defaultValue {
                    overrideStore.removeOverride(for: flag)
                } else {
                    overrideStore.setOverride(newValue, for: flag)
                }
                provider.objectWillChange.send()
            }
        }
        .padding(.vertical, 4)
    }
}
