import Foundation
import FoxDebugSettings
import Testing

@Suite("Debug setting definitions")
struct DebugSettingDefinitionTests {
    @Test("The macro uses the property name as the key and passes every argument through")
    func macroExpansionAtRuntime() {
        let stand = TestSettings.stand.descriptor
        #expect(stand.key == "stand")
        #expect(stand.displayName == "Stand")
        #expect(stand.group == .network)
        #expect(stand.defaultRawValue == "production")
        #expect(stand.acceptsRemote == false)

        let logLevel = TestSettings.logLevel.descriptor
        #expect(logLevel.acceptsRemote == true)
        #expect(logLevel.defaultRawValue == "error")
    }

    @Test("A choice lists every option in declaration order with its title")
    func choiceOptions() {
        #expect(TestSettings.stand.descriptor.kind == .choice(options: [
            .init(rawValue: "development", title: "Development"),
            .init(rawValue: "staging", title: "Staging"),
            .init(rawValue: "production", title: "Production"),
        ]))
    }

    @Test("An option without its own title shows its raw value")
    func defaultTitle() {
        #expect(LogLevel.debug.title == "debug")
    }

    @Test("A text setting carries its placeholder and defaults to an empty string")
    func textDefaults() {
        #expect(TestSettings.customURL.descriptor.kind == .text(placeholder: "https://…"))
        #expect(TestSettings.customURL.defaultValue == "")
        #expect(TestSettings.greeting.descriptor.kind == .text(placeholder: ""))
    }

    @Test("The container collects exactly the @DebugSetting members, in declaration order")
    func containerCollectsAll() {
        #expect(TestSettings.all.map(\.key) == ["stand", "customURL", "logLevel", "greeting"])
    }

    @Test("A choice accepts only its options; a text setting accepts anything")
    func accepts() {
        #expect(TestSettings.stand.descriptor.accepts("staging"))
        #expect(!TestSettings.stand.descriptor.accepts("Staging"))
        #expect(!TestSettings.stand.descriptor.accepts(""))
        #expect(TestSettings.customURL.descriptor.accepts(""))
        #expect(TestSettings.customURL.descriptor.accepts("anything at all"))
    }
}

@Suite("DebugSettingRegistry")
@MainActor
struct DebugSettingRegistryTests {
    @Test("Register keeps registration order")
    func order() {
        let sut = DebugSettingRegistry()
        sut.register(TestSettings.all)
        #expect(sut.settings.map(\.key) == ["stand", "customURL", "logLevel", "greeting"])
    }

    @Test("Registering the same key twice lists it once")
    func duplicates() {
        let sut = DebugSettingRegistry()
        sut.register(TestSettings.all)
        sut.register([TestSettings.stand.descriptor])
        #expect(sut.settings.count == TestSettings.all.count)
    }

    @Test("Groups are unique and in order of first appearance")
    func groups() {
        let sut = DebugSettingRegistry()
        sut.register(TestSettings.all)
        #expect(sut.groups == [.network, .logging])
    }

    @Test("An empty registry has no groups")
    func empty() {
        #expect(DebugSettingRegistry().groups.isEmpty)
    }
}

@Suite("DebugSettingStore")
struct DebugSettingStoreTests {
    private let defaults = UserDefaults(suiteName: "FoxDebugSettingsTests.\(UUID().uuidString)")!

    @Test("UserDefaults store round-trips, removes and namespaces its keys")
    func userDefaults() {
        let sut = UserDefaultsDebugSettingStore(defaults: defaults)
        #expect(sut.rawValue(forKey: "stand") == nil)

        sut.setRawValue("staging", forKey: "stand")
        #expect(sut.rawValue(forKey: "stand") == "staging")
        #expect(defaults.string(forKey: "FoxDebugSettings.value.stand") == "staging")
        #expect(defaults.string(forKey: "stand") == nil)

        sut.removeValue(forKey: "stand")
        #expect(sut.rawValue(forKey: "stand") == nil)
    }

    @Test("Values persist across store instances over the same defaults")
    func persistence() {
        UserDefaultsDebugSettingStore(defaults: defaults).setRawValue("x", forKey: "k")
        #expect(UserDefaultsDebugSettingStore(defaults: defaults).rawValue(forKey: "k") == "x")
    }

    @Test("In-memory store starts from its initial values and round-trips")
    func inMemory() {
        let sut = InMemoryDebugSettingStore(values: ["a": "1"])
        #expect(sut.rawValue(forKey: "a") == "1")
        sut.setRawValue("2", forKey: "a")
        #expect(sut.rawValue(forKey: "a") == "2")
        sut.removeValue(forKey: "a")
        #expect(sut.rawValue(forKey: "a") == nil)
    }
}
