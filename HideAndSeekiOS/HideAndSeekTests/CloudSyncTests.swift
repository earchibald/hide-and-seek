import Testing
import Foundation
@testable import HideAndSeek

@MainActor
struct CloudSyncTests {
    private let suiteName: String
    private let defaults: UserDefaults
    private let cloud: MockCloudStore

    init() {
        suiteName = "test.cloudSync.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        cloud = MockCloudStore()
    }

    private func cleanup() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test func statsManagerSeedsCloudOnFirstRun() {
        let manager = StatsManager(defaults: defaults, cloud: cloud)
        manager.recordGame(won: true, turnsRemaining: 5)
        let remote: GameStats? = cloud.load(GameStats.self, forKey: CloudKeys.stats)
        #expect(remote?.lifetimeWins == 1)
        cleanup()
    }

    @Test func statsManagerMergesRemoteOnInit() {
        var remote = GameStats()
        remote.lifetimeWins = 7
        remote.bestStreak = 4
        cloud.save(remote, forKey: CloudKeys.stats)

        let local = GameStats()
        if let encoded = try? JSONEncoder().encode(local) {
            defaults.set(encoded, forKey: "hideAndSeek.playerStats")
        }

        let manager = StatsManager(defaults: defaults, cloud: cloud)
        let stats = manager.getLifetimeStats()
        #expect(stats.wins == 7)
        #expect(stats.bestStreak == 4)
        cleanup()
    }

    @Test func externalChangeMergesIntoLocalStats() {
        let manager = StatsManager(defaults: defaults, cloud: cloud)
        manager.recordGame(won: true, turnsRemaining: 5)

        var remote = GameStats()
        remote.lifetimeWins = 10
        remote.bestStreak = 6
        cloud.simulateExternalChange(remote, forKey: CloudKeys.stats)

        let merged = manager.getLifetimeStats()
        #expect(merged.wins == 10)
        #expect(merged.bestStreak == 6)
        cleanup()
    }

    @Test func settingsStoreReadsRemoteOnInit() {
        var remote = GameSettings()
        remote.startingTurns = 42
        cloud.save(remote, forKey: CloudKeys.settings)

        let store = SettingsStore(defaults: defaults, cloud: cloud)
        #expect(store.settings.startingTurns == 42)
        cleanup()
    }

    @Test func settingsStoreFiresOnRemoteChange() {
        let store = SettingsStore(defaults: defaults, cloud: cloud)
        var received: GameSettings?
        store.onRemoteChange = { received = $0 }

        var remote = GameSettings()
        remote.startingTurns = 99
        cloud.simulateExternalChange(remote, forKey: CloudKeys.settings)

        #expect(received?.startingTurns == 99)
        #expect(store.settings.startingTurns == 99)
        cleanup()
    }
}
