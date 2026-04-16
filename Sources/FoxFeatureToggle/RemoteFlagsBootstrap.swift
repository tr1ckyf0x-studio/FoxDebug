import Foundation

/// Orchestrates the remote flags lifecycle: applies cached values immediately,
/// fetches fresh values in background, saves them for the next launch.
///
/// This "deferred config" pattern prevents flag flip-flopping mid-session:
/// the user sees consistent flag values throughout the app session, and new
/// values are only applied on the next launch.
///
/// Example:
/// ```swift
/// let bootstrap = RemoteFlagsBootstrap(
///     fetcher: MyRemoteFlagsFetcher(),
///     cache: UserDefaultsRemoteFlagsCache(),
///     provider: featureToggleProvider
/// )
/// bootstrap.run()
/// ```
public struct RemoteFlagsBootstrap: Sendable {
    private let fetcher: any RemoteFlagsFetcher
    private let cache: any RemoteFlagsCache
    private let provider: FeatureToggleProvider

    public init(
        fetcher: any RemoteFlagsFetcher,
        cache: any RemoteFlagsCache,
        provider: FeatureToggleProvider
    ) {
        self.fetcher = fetcher
        self.cache = cache
        self.provider = provider
    }

    /// Applies cached values to the provider and fetches fresh values for the next launch.
    ///
    /// - Cached values are applied to the current session immediately.
    /// - Fresh values are fetched asynchronously and saved to cache. They do NOT
    ///   affect the current session — they take effect on the next app launch.
    public func run() {
        let cachedFlags = cache.load()
        let fetcher = fetcher
        let cache = cache
        let provider = provider

        Task {
            await provider.loadRemoteFlags(cachedFlags)
        }

        Task {
            do {
                let fresh = try await fetcher.fetch()
                cache.save(fresh)
            } catch {
                // Silent failure: cached values remain in use, next launch will retry.
            }
        }
    }
}
