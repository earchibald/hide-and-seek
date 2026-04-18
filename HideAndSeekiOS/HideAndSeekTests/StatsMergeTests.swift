import Testing
import Foundation
@testable import HideAndSeek

struct StatsMergeTests {
    private func result(_ won: Bool, _ offset: TimeInterval) -> GameResult {
        GameResult(won: won, turnsRemaining: won ? 5 : 0, date: Date(timeIntervalSince1970: offset))
    }

    @Test func takesMaxOfLifetimeCounters() {
        var local = GameStats(); local.lifetimeWins = 5; local.lifetimeLosses = 2
        var remote = GameStats(); remote.lifetimeWins = 3; remote.lifetimeLosses = 4
        let merged = StatsMerge.merge(local: local, remote: remote)
        #expect(merged.lifetimeWins == 5)
        #expect(merged.lifetimeLosses == 4)
    }

    @Test func takesMaxBestStreakAndKeepsLocalCurrentStreak() {
        var local = GameStats(); local.bestStreak = 3; local.currentStreak = 2
        var remote = GameStats(); remote.bestStreak = 7; remote.currentStreak = 99
        let merged = StatsMerge.merge(local: local, remote: remote)
        #expect(merged.bestStreak == 7)
        #expect(merged.currentStreak == 2)
    }

    @Test func lastMilestoneTakesMax() {
        var local = GameStats(); local.lastMilestone = 10
        var remote = GameStats(); remote.lastMilestone = 25
        #expect(StatsMerge.merge(local: local, remote: remote).lastMilestone == 25)

        var onlyLocal = GameStats(); onlyLocal.lastMilestone = 50
        #expect(StatsMerge.merge(local: onlyLocal, remote: GameStats()).lastMilestone == 50)

        #expect(StatsMerge.merge(local: GameStats(), remote: GameStats()).lastMilestone == nil)
    }

    @Test func historyUnionsAndDedupes() {
        let a = result(true, 1)
        let b = result(false, 2)
        let c = result(true, 3)
        var local = GameStats(); local.gameHistory = [a, b]
        var remote = GameStats(); remote.gameHistory = [b, c]
        let merged = StatsMerge.merge(local: local, remote: remote)
        #expect(merged.gameHistory == [a, b, c])
    }

    @Test func historyTrimsToLimitKeepingMostRecent() {
        var local = GameStats()
        var remote = GameStats()
        local.gameHistory = (0..<60).map { result($0 % 2 == 0, TimeInterval($0)) }
        remote.gameHistory = (60..<120).map { result($0 % 2 == 0, TimeInterval($0)) }
        let merged = StatsMerge.merge(local: local, remote: remote, historyLimit: 100)
        #expect(merged.gameHistory.count == 100)
        #expect(merged.gameHistory.first?.date == Date(timeIntervalSince1970: 20))
        #expect(merged.gameHistory.last?.date == Date(timeIntervalSince1970: 119))
    }
}
