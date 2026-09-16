# Debug settings

A debug setting is a value the app reads rather than a switch it flips: which server to talk to, how
much to log, an address to override. There are two kinds.

| Type | Menu control | Value in code |
|------|--------------|---------------|
| `DebugText` | text field | `String` |
| `DebugChoice<Option>` | picker over every case of `Option` | `Option` |

## Declaring settings

```swift
import FoxDebugSettings

extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
}

enum LogLevel: String, DebugChoiceOption {
    case verbose, info, error

    var title: String { rawValue.capitalized }   // optional; defaults to rawValue
}

@DebugSettingContainer
enum NetworkSettings {
    @DebugSetting<LogLevel>(displayName: "Log level", group: .network, defaultValue: .error)
    static var logLevel: DebugChoice<LogLevel>

    @DebugSetting(displayName: "Proxy host", group: .network, placeholder: "192.168.0.10:8888")
    static var proxyHost: DebugText

    @DebugSetting(displayName: "Request timeout, s", group: .network, defaultValue: "30", acceptsRemote: true)
    static var requestTimeout: DebugText
}
```

### Arguments

| Argument | `DebugText` | `DebugChoice` | Default |
|----------|-------------|---------------|---------|
| `displayName` | required | required | — |
| `group` | required | required | — |
| `defaultValue` | `String` | an `Option` case, **required** | `""` for text |
| `placeholder` | shown in the empty field | not allowed | `""` |
| `acceptsRemote` | may a backend set it | may a backend set it | `false` |

### Giving a choice its default

Macro arguments are type-checked before the property they annotate is known, so `.error` alone has no
type to resolve against. Either name the type on the attribute, as above, or spell the value out:

```swift
@DebugSetting(displayName: "Log level", group: .network, defaultValue: LogLevel.error)
static var logLevel: DebugChoice<LogLevel>
```

### Rules the macro enforces

Each of these is reported at the attribute, not as a confusing error inside generated code:

- the property is a `static var` — not `let`, not an instance property;
- its type is written out as `DebugText` or `DebugChoice<Option>` — not inferred, not optional;
- a `DebugChoice` has a `defaultValue` and no `placeholder`.

### Options

An option is any `String`-backed enum conforming to `DebugChoiceOption`. The picker lists `allCases`
in declaration order, showing `title`. The stored value is the `rawValue`, so **renaming a raw value
loses what people selected**; renaming the case while keeping the raw value is safe.

Removing a case is safe too: a stored or remote raw value that no longer matches an option is ignored
and the setting falls back. The menu still offers **Reset** for it, so the leftover can be cleared.

## Registering and reading

```swift
let settings = DebugSettingsProvider(store: UserDefaultsDebugSettingStore())

let registry = DebugSettingRegistry()
registry.register(NetworkSettings.all)

debugMenuRegistry.register(
    DebugSettingsSection(provider: settings, registry: registry, footer: "Applied on next launch.")
)
```

```swift
let level: LogLevel = settings.value(NetworkSettings.logLevel)
let proxy: String = settings.value(NetworkSettings.proxyHost)
```

Two different settings with the same key — `baseURL` declared in two containers — would share one
stored value, so registering both asserts in debug builds. Registering the same container twice is
harmless.

## How a value is resolved

1. **Local value** — set in the menu, if the setting can hold it.
2. **Remote value** — only when `acceptsRemote: true`, and only if the setting can hold it.
3. **`defaultValue`.**

`acceptsRemote` is off by default on purpose. A setting that points the app somewhere — a server, a
proxy — must never be switchable by whoever controls the remote config.

An empty string is a real local value for a text setting: clearing the field in the menu stores `""`,
which outranks the remote value and the default. **Reset** is how to go back.

`settings.source(for: NetworkSettings.logLevel.descriptor)` returns `.local`, `.remote` or
`.defaultValue`; the menu shows it as a `LOCAL` or `REMOTE` badge.

## Threading

`DebugSettingsProvider` is `Sendable` and not bound to any actor. Every call is synchronous and safe from
any thread — settings typically configure infrastructure built off the main thread, such as a URL
session or a logger.

One catch: in a module compiled with **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**, your container
and group extension are main-actor isolated like everything else in that module, and reading
`NetworkSettings.logLevel` from a background context will not compile. Opt them out:

```swift
nonisolated extension DebugSettingGroup {
    static let network = DebugSettingGroup(rawValue: "Network")
}

@DebugSettingContainer
nonisolated enum NetworkSettings { … }
```

## When a change takes effect

The provider reads the store on every call, so the next read after an edit sees the new value.
Nothing is pushed, though: `DebugSettingsProvider` is not `@Observable`, and objects already built from
the old value keep it.

Most settings are worth reading **once at launch** — a base URL baked into a network client, a log
level handed to a logger. Say so in the section's `footer`, so the person changing it knows to relaunch.
Settings read at the point of use, like a timeout per request, apply immediately.

In the menu, a choice is a picker at the trailing edge of its row and a text setting is a field under
its title. A picked option is saved at once. Typed text is saved on **Return** or when the field loses
focus, never per keystroke, so half-typed values never reach the app.

**Reset** removes the stored value. For a text setting it is a button beside the title; for a choice it
is the last item of the picker's menu. Either appears only while a value is stored.
