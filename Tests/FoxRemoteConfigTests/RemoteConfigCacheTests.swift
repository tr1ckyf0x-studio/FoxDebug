import Foundation
import Testing
@testable import FoxRemoteConfig

@Suite("RemoteConfigCache")
struct RemoteConfigCacheTests {
    private let defaults = UserDefaults(suiteName: "FoxRemoteConfigTests.\(UUID().uuidString)")!

    private func makeSUT() -> UserDefaultsRemoteConfigCache {
        UserDefaultsRemoteConfigCache(defaults: defaults)
    }

    @Test("Returns an empty config when nothing is cached")
    func emptyCache() {
        #expect(makeSUT().load() == .empty)
    }

    @Test("Save and load round-trip flags and settings")
    func roundTrip() {
        let sut = makeSUT()
        let config = RemoteConfig(flags: ["flagA": true, "flagB": false], settings: ["stand": "production"])
        sut.save(config)
        #expect(sut.load() == config)
    }

    @Test("A new instance over the same defaults reads what the previous one saved")
    func persistsAcrossInstances() {
        let config = RemoteConfig(flags: ["flag": true], settings: ["url": "https://example.com"])
        makeSUT().save(config)
        #expect(makeSUT().load() == config)
    }

    @Test("Save replaces the previous config rather than merging into it")
    func saveReplaces() {
        let sut = makeSUT()
        sut.save(RemoteConfig(flags: ["flagA": true], settings: ["a": "1"]))
        sut.save(RemoteConfig(flags: ["flagB": false]))
        #expect(sut.load() == RemoteConfig(flags: ["flagB": false]))
    }

    @Test("Clear empties the cache")
    func clear() {
        let sut = makeSUT()
        sut.save(RemoteConfig(flags: ["flag": true]))
        sut.clear()
        #expect(sut.load() == .empty)
    }

    @Test("Unreadable data loads as an empty config instead of failing")
    func corruptData() {
        defaults.set(Data("not json".utf8), forKey: UserDefaultsRemoteConfigCache.storageKey)
        #expect(makeSUT().load() == .empty)
    }

    @Test("A value of the wrong type under the key loads as an empty config")
    func wrongStoredType() {
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.storageKey)
        #expect(makeSUT().load() == .empty)
    }

    @Test("Flags cached by 2.x load until the first save, which then drops them")
    func legacyFlagsCache() {
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey)
        let sut = makeSUT()
        #expect(sut.load() == RemoteConfig(flags: ["flag": true]))

        sut.save(RemoteConfig(settings: ["a": "1"]))
        #expect(sut.load() == RemoteConfig(settings: ["a": "1"]))
        #expect(defaults.object(forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey) == nil)
    }

    @Test("The current cache wins over a leftover 2.x cache")
    func currentBeatsLegacy() {
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey)
        let sut = makeSUT()
        sut.save(RemoteConfig(flags: ["flag": false]))
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey)
        #expect(sut.load() == RemoteConfig(flags: ["flag": false]))
    }

    @Test("A corrupt current cache loads as empty rather than resurrecting a leftover 2.x cache")
    func corruptCurrentDoesNotFallBackToLegacy() {
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey)
        defaults.set(Data("not json".utf8), forKey: UserDefaultsRemoteConfigCache.storageKey)
        #expect(makeSUT().load() == .empty)
    }

    @Test("Clear also drops a 2.x cache")
    func clearDropsLegacy() {
        defaults.set(["flag": true], forKey: UserDefaultsRemoteConfigCache.legacyFlagsKey)
        makeSUT().clear()
        #expect(makeSUT().load() == .empty)
    }
}

@Suite("RemoteConfig decoding")
struct RemoteConfigDecodingTests {
    @Test("A payload without settings or flags decodes with that dictionary empty")
    func missingKeys() throws {
        let flagsOnly = try JSONDecoder().decode(RemoteConfig.self, from: Data(#"{"flags":{"a":true}}"#.utf8))
        #expect(flagsOnly == RemoteConfig(flags: ["a": true]))

        let empty = try JSONDecoder().decode(RemoteConfig.self, from: Data("{}".utf8))
        #expect(empty == .empty)
    }

    @Test("Unknown keys are ignored")
    func unknownKeys() throws {
        let config = try JSONDecoder().decode(
            RemoteConfig.self,
            from: Data(#"{"settings":{"s":"v"},"numbers":{"n":1}}"#.utf8)
        )
        #expect(config == RemoteConfig(settings: ["s": "v"]))
    }

    @Test("A value of the wrong type still fails, instead of being silently dropped")
    func wrongType() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RemoteConfig.self, from: Data(#"{"flags":{"a":"yes"}}"#.utf8))
        }
    }
}
