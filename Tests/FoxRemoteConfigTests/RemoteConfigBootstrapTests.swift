import Foundation
import os
import Testing
@testable import FoxRemoteConfig

@Suite("RemoteConfigBootstrap")
@MainActor
struct RemoteConfigBootstrapTests {
    private static let cached = RemoteConfig(flags: ["flag": true], settings: ["stand": "development"])
    private static let fresh = RemoteConfig(flags: ["flag": false], settings: ["stand": "production"])

    @Test("Applies the cached config to every consumer before run returns")
    func appliesCacheSynchronously() {
        let first = RecordingConsumer()
        let second = RecordingConsumer()
        let bootstrap = RemoteConfigBootstrap(
            fetcher: StubFetcher(result: .success(Self.fresh)),
            cache: InMemoryCache(config: Self.cached),
            consumers: [first, second]
        )

        bootstrap.run()

        #expect(first.applied == [Self.cached])
        #expect(second.applied == [Self.cached])
    }

    @Test("Saves the fetched config to the cache without applying it to the current session")
    func freshConfigWaitsForNextLaunch() async {
        let consumer = RecordingConsumer()
        let cache = InMemoryCache(config: Self.cached)
        let bootstrap = RemoteConfigBootstrap(
            fetcher: StubFetcher(result: .success(Self.fresh)),
            cache: cache,
            consumers: [consumer]
        )

        await bootstrap.run().value

        #expect(cache.load() == Self.fresh)
        #expect(consumer.applied == [Self.cached])
    }

    @Test("A failed fetch leaves the cache untouched and reports the error")
    func fetchFailure() async {
        let cache = InMemoryCache(config: Self.cached)
        let reported = OSAllocatedUnfairLock<[String]>(initialState: [])
        let bootstrap = RemoteConfigBootstrap(
            fetcher: StubFetcher(result: .failure(StubError.offline)),
            cache: cache,
            consumers: []
        )

        await bootstrap.run { error in
            reported.withLock { $0.append(String(describing: error)) }
        }.value

        #expect(cache.load() == Self.cached)
        #expect(reported.withLock { $0 } == [String(describing: StubError.offline)])
    }

    @Test("A cancelled fetch neither saves nor reports")
    func cancellation() async {
        let cache = InMemoryCache(config: Self.cached)
        let reported = OSAllocatedUnfairLock(initialState: false)
        let gate = Gate()
        let bootstrap = RemoteConfigBootstrap(
            fetcher: GatedFetcher(gate: gate, result: Self.fresh),
            cache: cache,
            consumers: []
        )

        let task = bootstrap.run { _ in reported.withLock { $0 = true } }
        task.cancel()
        await gate.open()
        await task.value

        #expect(cache.load() == Self.cached)
        #expect(reported.withLock { $0 } == false)
    }

    @Test("A fetcher that throws CancellationError on cancellation is not reported as a failure")
    func cancellationErrorNotReported() async {
        let reported = OSAllocatedUnfairLock(initialState: false)
        let bootstrap = RemoteConfigBootstrap(
            fetcher: StubFetcher(result: nil),
            cache: InMemoryCache(config: .empty),
            consumers: []
        )

        await bootstrap.run { _ in reported.withLock { $0 = true } }.value

        #expect(reported.withLock { $0 } == false)
    }

    @Test("An empty cache applies an empty config, so stale remote values from a previous run are dropped")
    func emptyCacheAppliesEmpty() {
        let consumer = RecordingConsumer()
        RemoteConfigBootstrap(
            fetcher: StubFetcher(result: .success(Self.fresh)),
            cache: InMemoryCache(config: .empty),
            consumers: [consumer]
        )
        .run()

        #expect(consumer.applied == [.empty])
    }
}

@MainActor
private final class RecordingConsumer: AppliesRemoteConfig {
    private(set) var applied: [RemoteConfig] = []

    func applyRemoteConfig(_ config: RemoteConfig) {
        applied.append(config)
    }
}

private enum StubError: Error {
    case offline
}

private struct StubFetcher: RemoteConfigFetcher {
    /// `nil` throws `CancellationError`, as a URLSession-based fetcher does when its task is cancelled.
    let result: Result<RemoteConfig, StubError>?

    func fetch() async throws -> RemoteConfig {
        guard let result else {
            throw CancellationError()
        }
        return try result.get()
    }
}

/// Holds a fetch until the test opens it, so the test can cancel the task while the fetch is in flight.
private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else {
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

/// Ignores cancellation and returns normally, like a fetcher that does not check for it.
private struct GatedFetcher: RemoteConfigFetcher {
    let gate: Gate
    let result: RemoteConfig

    func fetch() async throws -> RemoteConfig {
        await gate.wait()
        return result
    }
}

private final class InMemoryCache: RemoteConfigCache {
    private let config: OSAllocatedUnfairLock<RemoteConfig>

    init(config: RemoteConfig) {
        self.config = OSAllocatedUnfairLock(initialState: config)
    }

    func load() -> RemoteConfig {
        config.withLock { $0 }
    }

    func save(_ config: RemoteConfig) {
        self.config.withLock { $0 = config }
    }

    func clear() {
        config.withLock { $0 = .empty }
    }
}
