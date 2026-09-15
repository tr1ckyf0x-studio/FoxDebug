# Recipes

## Switching servers from the debug menu

A choice of stand, plus free text for anything not on the list:

```swift
import Foundation
import FoxDebugSettings

extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
}

enum Stand: String, DebugChoiceOption {
    case development, staging, production, custom

    var title: String { rawValue.capitalized }

    var baseURL: URL? {
        switch self {
        case .development: URL(string: "https://dev.api.example.com")
        case .staging: URL(string: "https://staging.api.example.com")
        case .production: URL(string: "https://api.example.com")
        case .custom: nil
        }
    }
}

@DebugSettingContainer
enum NetworkSettings {
    @DebugSetting<Stand>(displayName: "Stand", group: .network, defaultValue: .production)
    static var stand: DebugChoice<Stand>

    @DebugSetting(displayName: "Custom base URL", group: .network, placeholder: "https://…")
    static var customBaseURL: DebugText
}
```

Neither setting has `acceptsRemote`, so a backend cannot point the app elsewhere.

Resolve the URL **once, at launch**, and build the network client from it. Changing servers under live
requests — with tokens issued by the old server — is not worth supporting for a debug tool; tell the
tester instead:

```swift
DebugSettingsSection(provider: settings, registry: registry, footer: "Stand changes apply on next launch.")
```

If the app keeps a session, store it per stand (for example, key the Keychain item by the stand's raw
value). Switching then lands on the sign-in screen, and switching back restores the previous session.

### Making sure a production build ignores it

When the debug menu ships in TestFlight builds, the same binary goes to the App Store, and so does a
stored stand. Decide at launch where the build came from, and ignore the setting in an App Store
install:

```swift
import StoreKit

enum InstallSource: Sendable {
    case appStore, testFlight, development

    static func current() async -> InstallSource {
        // Unknown means App Store: failing towards production is the safe direction.
        guard let result = try? await AppTransaction.shared else {
            return .appStore
        }
        let environment = switch result {
        case let .verified(transaction), let .unverified(transaction, _): transaction.environment
        }
        if environment == .sandbox {
            return .testFlight
        }
        if environment == .xcode {
            return .development
        }
        return .appStore
    }
}

struct BaseURLResolver: Sendable {
    let settings: DebugSettingsProvider
    let installSource: InstallSource

    func resolve() -> URL {
        let production = Stand.production.baseURL!
        guard installSource != .appStore else {
            return production
        }

        let stand = settings.value(NetworkSettings.stand)
        guard stand == .custom else {
            return stand.baseURL ?? production
        }

        let custom = URL(string: settings.value(NetworkSettings.customBaseURL))
        return custom?.scheme == "https" ? custom! : production
    }
}
```

The fallback has a cost worth knowing: a development build that cannot reach StoreKit on its first
launch runs against production. Relaunching once online fixes it; the opposite failure — an App Store
user on a development server — would not fix itself.

## Keeping the menu out of production

Two approaches, depending on what the App Store build is allowed to contain.

**The menu must not ship at all.** Wrap every use of FoxDebug's UI in a compilation condition that only
debug-capable configurations define, for example `DEBUG_MENU` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.
`#if` works inside a modifier chain, so the presentation stays in one place:

```swift
import SwiftUI
#if DEBUG_MENU
import FoxDebugMenu
#endif

struct RootScene: View {
    #if DEBUG_MENU
    let debugMenu: DebugMenuRegistry
    @State private var isDebugMenuPresented = false
    #endif

    var body: some View {
        ContentView()
            #if DEBUG_MENU
            .sheet(isPresented: $isDebugMenuPresented) {
                DebugMenuView(registry: debugMenu)
            }
            .onShakeGesture { isDebugMenuPresented = true }
            #endif
    }
}
```

Flags and settings themselves still compile in every configuration — code reads them everywhere — and
simply resolve to remote values and defaults when nobody can open the menu. This only works with a
build configuration that differs from the one testers receive, which means the binary Apple reviews is
not the binary your testers tried.

**One binary everywhere.** Keep the menu compiled in and make it unreachable in an App Store install,
using `InstallSource` from the recipe above: do not register the shake handler when it is `.appStore`.
Testers and users run the same build; the cost is that the menu's code ships.

## Reading settings off the main thread at launch

Resolve what infrastructure needs into plain values before handing it out, so nothing else depends on
FoxDebug:

```swift
struct NetworkConfiguration: Sendable {
    let baseURL: URL
    let logLevel: LogLevel
}

let configuration = NetworkConfiguration(
    baseURL: BaseURLResolver(settings: settings, installSource: installSource).resolve(),
    logLevel: settings.value(NetworkSettings.logLevel)
)
```

`DebugSettingsProvider` can be called from any thread, so this works in a detached task or an actor
initialiser just as well. In a module with default main-actor isolation, mark the container and group
extension `nonisolated` first — see [Debug settings → Threading](debug-settings.md#threading).

## Feature modules without a FoxDebug dependency

A feature module does not need to import FoxDebug to be controlled by it. Declare what it needs as a
protocol inside the module:

```swift
// CheckoutFeature module
@MainActor
public protocol CheckoutConfiguration {
    var isOneTapEnabled: Bool { get }
}
```

`@MainActor`, because flags are read on the main actor: a non-isolated requirement could not be
satisfied by an adapter that reads them.

And adapt in the app, which is the only place that knows about FoxDebug:

```swift
// App
@MainActor
struct CheckoutConfigurationAdapter: CheckoutConfiguration {
    let flags: FeatureToggleProvider

    var isOneTapEnabled: Bool { flags.isEnabled(CheckoutFlags.oneTap) }
}
```

The module's tests then use a two-line stub instead of a provider, and the module can be reused in an
app without FoxDebug.

## A section with actions

Not every debug tool is a value. A section is any SwiftUI screen, so actions fit as well:

```swift
struct CacheDebugSection: DebugSection {
    let id = "cache"
    let title = "Cache"
    let icon = Image(systemName: "externaldrive")

    let cache: ImageCache

    var body: some View {
        List {
            Button("Clear image cache", role: .destructive) { cache.removeAll() }
            Button("Reset remote config cache") { UserDefaultsRemoteConfigCache().clear() }
        }
        .scrollContentBackground(.hidden)
        .background(Color.foxDebugBackground)
        .navigationTitle("Cache")
    }
}
```

Clearing the remote config cache makes the next launch start from defaults, as a fresh install would.
