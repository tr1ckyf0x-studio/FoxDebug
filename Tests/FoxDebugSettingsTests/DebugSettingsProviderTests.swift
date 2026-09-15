import FoxDebugSettings
import FoxRemoteConfig
import Testing

@Suite("DebugSettingsProvider")
struct DebugSettingsProviderTests {
    private let store = InMemoryDebugSettingStore()

    private func makeSUT() -> DebugSettingsProvider {
        DebugSettingsProvider(store: store)
    }

    // MARK: - Defaults

    @Test("Returns the default when nothing is set")
    func defaults() {
        let sut = makeSUT()
        #expect(sut.value(TestSettings.stand) == .production)
        #expect(sut.value(TestSettings.customURL) == "")
        #expect(sut.value(TestSettings.greeting) == "hello")
        #expect(sut.source(for: TestSettings.stand.descriptor) == .defaultValue)
    }

    // MARK: - Local values

    @Test("A local value wins over the default")
    func localValue() {
        let sut = makeSUT()
        sut.setRawValue(Stand.staging.rawValue, for: TestSettings.stand.descriptor)
        sut.setRawValue("https://dev.example.com", for: TestSettings.customURL.descriptor)

        #expect(sut.value(TestSettings.stand) == .staging)
        #expect(sut.value(TestSettings.customURL) == "https://dev.example.com")
        #expect(sut.source(for: TestSettings.stand.descriptor) == .local)
    }

    @Test("An empty string is a legitimate local text value, not an absent one")
    func emptyTextIsLocal() {
        let sut = makeSUT()
        sut.setRawValue("", for: TestSettings.greeting.descriptor)
        #expect(sut.value(TestSettings.greeting) == "")
        #expect(sut.source(for: TestSettings.greeting.descriptor) == .local)
    }

    @Test("Reset drops the local value and falls back")
    func reset() {
        let sut = makeSUT()
        sut.setRawValue(Stand.development.rawValue, for: TestSettings.stand.descriptor)
        sut.reset(TestSettings.stand.descriptor)
        #expect(sut.value(TestSettings.stand) == .production)
        #expect(sut.source(for: TestSettings.stand.descriptor) == .defaultValue)
    }

    @Test("A stored choice that is no longer an option falls back to the default")
    func removedOption() {
        store.setRawValue("qa", forKey: TestSettings.stand.descriptor.key)
        let sut = makeSUT()
        #expect(sut.value(TestSettings.stand) == .production)
        #expect(sut.source(for: TestSettings.stand.descriptor) == .defaultValue)
    }

    @Test("A stored value the setting no longer accepts still counts as stored, and reset removes it")
    func staleStoredValue() {
        store.setRawValue("qa", forKey: TestSettings.stand.descriptor.key)
        let sut = makeSUT()
        #expect(sut.hasStoredValue(for: TestSettings.stand.descriptor))
        sut.reset(TestSettings.stand.descriptor)
        #expect(!sut.hasStoredValue(for: TestSettings.stand.descriptor))
        #expect(store.rawValue(forKey: "stand") == nil)
    }

    @Test("The provider reads the store on every call, so a value written elsewhere is seen at once")
    func readsThrough() {
        let sut = makeSUT()
        store.setRawValue(Stand.development.rawValue, forKey: "stand")
        #expect(sut.value(TestSettings.stand) == .development)
    }

    // MARK: - Remote values

    @Test("A remote value applies when the setting accepts remote")
    func remoteAccepted() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "debug", "greeting": "hi"]))
        #expect(sut.value(TestSettings.logLevel) == .debug)
        #expect(sut.value(TestSettings.greeting) == "hi")
        #expect(sut.source(for: TestSettings.logLevel.descriptor) == .remote)
    }

    @Test("A remote value is ignored when the setting does not accept remote")
    func remoteIgnored() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["stand": "development", "customURL": "https://evil.example"]))
        #expect(sut.value(TestSettings.stand) == .production)
        #expect(sut.value(TestSettings.customURL) == "")
        #expect(sut.source(for: TestSettings.stand.descriptor) == .defaultValue)
    }

    @Test("A local value wins over a remote one")
    func localBeatsRemote() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "debug"]))
        sut.setRawValue(LogLevel.error.rawValue, for: TestSettings.logLevel.descriptor)
        #expect(sut.value(TestSettings.logLevel) == .error)
        #expect(sut.source(for: TestSettings.logLevel.descriptor) == .local)
    }

    @Test("Reset falls back to the remote value when there is one")
    func resetFallsBackToRemote() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "debug"]))
        sut.setRawValue(LogLevel.error.rawValue, for: TestSettings.logLevel.descriptor)
        sut.reset(TestSettings.logLevel.descriptor)
        #expect(sut.value(TestSettings.logLevel) == .debug)
        #expect(sut.source(for: TestSettings.logLevel.descriptor) == .remote)
    }

    @Test("A remote choice that is not an option falls back to the default")
    func invalidRemoteChoice() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "verbose"]))
        #expect(sut.value(TestSettings.logLevel) == .error)
        #expect(sut.source(for: TestSettings.logLevel.descriptor) == .defaultValue)
    }

    @Test("An invalid local choice is skipped in favour of a valid remote one")
    func invalidLocalFallsToRemote() {
        store.setRawValue("verbose", forKey: "logLevel")
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "debug"]))
        #expect(sut.value(TestSettings.logLevel) == .debug)
    }

    @Test("Applying a config replaces earlier remote values instead of merging")
    func applyReplaces() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(settings: ["logLevel": "debug", "greeting": "hi"]))
        sut.applyRemoteConfig(RemoteConfig(settings: ["greeting": "hey"]))
        #expect(sut.value(TestSettings.logLevel) == .error)
        #expect(sut.value(TestSettings.greeting) == "hey")
    }

    @Test("Remote flags do not leak into settings with the same key")
    func flagsDoNotLeak() {
        let sut = makeSUT()
        sut.applyRemoteConfig(RemoteConfig(flags: ["greeting": true]))
        #expect(sut.value(TestSettings.greeting) == "hello")
    }

    // MARK: - Concurrency

    @Test("Reads, writes and remote updates from many tasks at once stay consistent")
    func concurrentAccess() async {
        let sut = makeSUT()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask {
                    switch index % 4 {
                    case 0: sut.setRawValue(Stand.staging.rawValue, for: TestSettings.stand.descriptor)
                    case 1: sut.applyRemoteConfig(RemoteConfig(settings: ["greeting": "hi \(index)"]))
                    case 2: _ = sut.value(TestSettings.stand)
                    default: _ = sut.value(TestSettings.greeting)
                    }
                }
            }
        }
        #expect(sut.value(TestSettings.stand) == .staging)
        #expect(sut.value(TestSettings.greeting).hasPrefix("hi "))
    }
}
