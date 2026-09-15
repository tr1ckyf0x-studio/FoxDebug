import FoxDebugMenu
import FoxDebugSettings
import SwiftUI

/// One debug setting: its name, where its value comes from, and the control that changes it.
///
/// The control edits a local copy and only a user's decision writes it: a picked option at once, typed
/// text on submit or when the field loses focus. Writing text per keystroke would store every
/// intermediate string — an emptied field included — as a local value that outranks remote and default.
/// A value equal to the one already in effect is not written, so it does not turn into a local one.
struct DebugSettingRowView: View {
    let setting: DebugSettingDescriptor
    let provider: DebugSettingsProvider

    @State private var draft: String
    @State private var source: DebugSettingSource
    @State private var hasStoredValue: Bool
    @FocusState private var isEditing: Bool

    init(setting: DebugSettingDescriptor, provider: DebugSettingsProvider) {
        self.setting = setting
        self.provider = provider
        _draft = State(initialValue: provider.rawValue(for: setting))
        _source = State(initialValue: provider.source(for: setting))
        _hasStoredValue = State(initialValue: provider.hasStoredValue(for: setting))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacing) {
            HStack {
                Text(setting.displayName)
                    .font(.body)
                switch source {
                case .local: DebugBadge("LOCAL", color: .blue)
                case .remote: DebugBadge("REMOTE", color: .purple)
                case .defaultValue: EmptyView()
                }
                Spacer()
                // Keyed on the store rather than on `.local`: a stored option since removed from its enum
                // resolves as a fallback, yet still needs a way out of the store.
                if hasStoredValue {
                    Button("Reset", action: reset)
                        .buttonStyle(.borderless)
                        .font(.caption)
                }
            }
            control
        }
        .padding(.vertical, Metrics.verticalPadding)
        .onAppear {
            if !isEditing {
                reload()
            }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch setting.kind {
        case let .text(placeholder):
            TextField(placeholder, text: $draft)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .focused($isEditing)
                .onSubmit(commit)
                .onChange(of: isEditing) { _, isEditing in
                    if !isEditing {
                        commit()
                    }
                }
        case let .choice(options):
            Picker(setting.displayName, selection: choiceBinding) {
                ForEach(options, id: \.rawValue) { option in
                    Text(option.title).tag(option.rawValue)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var choiceBinding: Binding<String> {
        Binding {
            draft
        } set: { newValue in
            draft = newValue
            commit()
        }
    }

    private func commit() {
        guard draft != provider.rawValue(for: setting) else {
            return
        }
        provider.setRawValue(draft, for: setting)
        reload()
    }

    private func reset() {
        provider.reset(setting)
        reload()
    }

    private func reload() {
        draft = provider.rawValue(for: setting)
        source = provider.source(for: setting)
        hasStoredValue = provider.hasStoredValue(for: setting)
    }

    private enum Metrics {
        static let spacing: CGFloat = 8
        static let verticalPadding: CGFloat = 4
    }
}
