/// Orchestrates the remote config lifecycle: applies cached values immediately, fetches fresh values
/// in the background, saves them for the next launch.
///
/// This "deferred config" pattern keeps values stable within a session: the user never sees a flag or
/// a setting change under them, and freshly fetched values take effect on the next launch.
///
/// ```swift
/// RemoteConfigBootstrap(
///     fetcher: BackendRemoteConfigFetcher(),
///     cache: UserDefaultsRemoteConfigCache(),
///     consumers: [featureToggleProvider, debugSettingsProvider]
/// )
/// .run()
/// ```
public struct RemoteConfigBootstrap: Sendable {
    private let fetcher: any RemoteConfigFetcher
    private let cache: any RemoteConfigCache
    private let consumers: [any AppliesRemoteConfig]

    public init(
        fetcher: any RemoteConfigFetcher,
        cache: any RemoteConfigCache,
        consumers: [any AppliesRemoteConfig]
    ) {
        self.fetcher = fetcher
        self.cache = cache
        self.consumers = consumers
    }

    /// Applies the cached config to every consumer, then fetches a fresh one for the next launch.
    ///
    /// The cached config is applied **before this method returns**, so anything the app reads after
    /// `run()` already sees it. The fetched config never touches the current session.
    ///
    /// Call it **once per launch**. A second call would apply whatever the first fetch has cached since,
    /// changing values mid-session — exactly what the deferred pattern exists to prevent.
    ///
    /// - Parameter onFetchFailure: Called when the fetch throws. The cache is left as it was.
    /// - Returns: The fetch task. Cancelling it leaves the cache untouched and reports nothing.
    @MainActor
    @discardableResult
    public func run(onFetchFailure: (@Sendable (any Error) -> Void)? = nil) -> Task<Void, Never> {
        let cached = cache.load()
        for consumer in consumers {
            consumer.applyRemoteConfig(cached)
        }

        let fetcher = fetcher
        let cache = cache
        return Task.detached {
            do {
                let fresh = try await fetcher.fetch()
                try Task.checkCancellation()
                cache.save(fresh)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                onFetchFailure?(error)
            }
        }
    }
}
