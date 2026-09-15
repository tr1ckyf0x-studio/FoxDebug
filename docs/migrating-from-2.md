# Migrating from 2.x

3.0.0 replaces the remote flags API with a remote config shared by flags and the new debug settings.
Apps that never used remote values only need to raise the version.

## Remote values

| 2.x | 3.0.0 |
|-----|-------|
| `RemoteFlagsFetcher` returning `[String: Bool]` | `RemoteConfigFetcher` returning `RemoteConfig` |
| `RemoteFlagsCache` / `UserDefaultsRemoteFlagsCache` | `RemoteConfigCache` / `UserDefaultsRemoteConfigCache` |
| `RemoteFlagsBootstrap(fetcher:cache:provider:)` | `RemoteConfigBootstrap(fetcher:cache:consumers:)` |
| `ProvidesFeatureToggle.loadRemoteFlags(_:) async` | `applyRemoteConfig(_:)`, synchronous |
| all in `FoxFeatureToggle` | all in `FoxRemoteConfig` — add the product |

A fetcher changes from:

```swift
func fetch() async throws -> [String: Bool] {
    try await api.flags()
}
```

to:

```swift
func fetch() async throws -> RemoteConfig {
    RemoteConfig(flags: try await api.flags())
}
```

And the bootstrap from `provider: flags` to `consumers: [flags]`.

## Behaviour changes

- **The cached config is applied before `run()` returns.** In 2.x it was applied in a task, so reads
  made right after launch could see defaults. If your app worked around that by waiting, the workaround
  can go.
- **The cache moved** from `FoxFeatureToggle.remoteCache` to `FoxRemoteConfig.cache`. Flags cached by
  2.x are still read until the first successful fetch saves over them, so updating does not drop them
  for a session.
- **`@FeatureToggle` forwards `displayName` as written.** Interpolated and escaped strings used to be cut
  short; they now show in full.
- **Flag keys drop backticks.** A flag declared as `` static var `default` `` was stored under
  `` `default` `` and is now stored under `default`, so an override set on it in 2.x is forgotten.
- **`#if`-guarded flags** now appear in `all` under their condition. They were silently missing before.

## Build

The macro plugin target is now `FoxDebugMacros`. Only a project that referred to
`FoxFeatureToggleMacros` by name — a build setting, a script — needs to change.
