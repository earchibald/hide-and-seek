import Testing
import Foundation
@testable import HideAndSeek

struct StatsManagerTests {
    private let suiteName: String
    private let defaults: UserDefaults
    private let manager: StatsManager

    init() {
        suiteName = "test.statsManager.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        manager = StatsManager(defaults: defaults)
    }

    private func cleanup() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test func emptyStateReturnsZeroStats() {
        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 0)
        #expect(stats.wins == 0)
        #expect(stats.losses == 0)
        #expect(stats.winRate == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.bestStreak == 0)
        cleanup()
    }

    @Test func recordWinIncrementsWinsAndStreak() {
        manager.recordGame(won: true, turnsRemaining: 5)
        let stats = manager.getLifetimeStats()
        #expect(stats.wins == 1)
        #expect(stats.losses == 0)
        #expect(stats.currentStreak == 1)
        cleanup()
    }

    @Test func recordLossIncrementsLossesAndResetsStreak() {
        manager.recordGame(won: true, turnsRemaining: 5)
        manager.recordGame(won: true, turnsRemaining: 3)
        manager.recordGame(won: false, turnsRemaining: 0)
        let stats = manager.getLifetimeStats()
        #expect(stats.wins == 2)
        #expect(stats.losses == 1)
        #expect(stats.currentStreak == 0)
        cleanup()
    }

    @Test func bestStreakTracksMaximum() {
        for _ in 0..<3 { manager.recordGame(won: true, turnsRemaining: 5) }
        manager.recordGame(won: false, turnsRemaining: 0)
        for _ in 0..<2 { manager.recordGame(won: true, turnsRemaining: 5) }

        let stats = manager.getLifetimeStats()
        #expect(stats.bestStreak == 3)
        #expect(stats.currentStreak == 2)
        cleanup()
    }

    @Test func historyTrimmingKeepsLast100() {
        for i in 0..<105 {
            manager.recordGame(won: i % 2 == 0, turnsRemaining: i % 2 == 0 ? 5 : 0)
        }
        let stats = manager.getLast100Stats()
        #expect(stats.gamesPlayed == 100)
        cleanup()
    }

    @Test func milestoneFirstReach() {
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        let milestone = manager.checkMilestone()
        #expect(milestone == 10)
        cleanup()
    }

    @Test func milestoneAlreadyReachedReturnsNil() {
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        _ = manager.checkMilestone()
        let milestone = manager.checkMilestone()
        #expect(milestone == nil)
        cleanup()
    }

    @Test func milestoneProgression() {
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        let first = manager.checkMilestone()
        #expect(first == 10)

        for _ in 0..<15 { manager.recordGame(won: true, turnsRemaining: 5) }
        let second = manager.checkMilestone()
        #expect(second == 25)
        cleanup()
    }

    @Test func getLifetimeStatsCalculatesWinRate() {
        for _ in 0..<3 { manager.recordGame(won: true, turnsRemaining: 5) }
        manager.recordGame(won: false, turnsRemaining: 0)

        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 4)
        #expect(stats.wins == 3)
        #expect(stats.losses == 1)
        #expect(stats.winRate == 75.0)
        cleanup()
    }

    @Test func getLast10StatsWindowedCalculation() {
        for _ in 0..<5 { manager.recordGame(won: false, turnsRemaining: 0) }
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }

        let last10 = manager.getLast10Stats()
        #expect(last10.gamesPlayed == 10)
        #expect(last10.wins == 10)
        #expect(last10.losses == 0)
        cleanup()
    }

    @Test func getLast100StatsWindowedCalculation() {
        for _ in 0..<50 { manager.recordGame(won: true, turnsRemaining: 5) }
        for _ in 0..<50 { manager.recordGame(won: false, turnsRemaining: 0) }

        let last100 = manager.getLast100Stats()
        #expect(last100.gamesPlayed == 100)
        #expect(last100.wins == 50)
        #expect(last100.losses == 50)
        cleanup()
    }

    @Test func clearStatsResetsEverything() {
        for _ in 0..<5 { manager.recordGame(won: true, turnsRemaining: 5) }
        manager.clearStats()

        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 0)
        #expect(stats.wins == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.bestStreak == 0)
        cleanup()
    }

    @Test func persistenceRoundTrip() {
        manager.recordGame(won: true, turnsRemaining: 5)
        manager.recordGame(won: true, turnsRemaining: 3)

        let manager2 = StatsManager(defaults: defaults)
        let stats = manager2.getLifetimeStats()
        #expect(stats.wins == 2)
        #expect(stats.currentStreak == 2)
        cleanup()
    }
}
