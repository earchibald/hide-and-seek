import Testing
import Foundation
@testable import HideAndSeek

struct GameStatsTests {
    @Test func emptyGameStatsRoundTrip() throws {
        let stats = GameStats()
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)

        #expect(decoded.gameHistory.isEmpty)
        #expect(decoded.lifetimeWins == 0)
        #expect(decoded.lifetimeLosses == 0)
        #expect(decoded.currentStreak == 0)
        #expect(decoded.bestStreak == 0)
        #expect(decoded.lastMilestone == nil)
    }

    @Test func populatedGameStatsRoundTrip() throws {
        var stats = GameStats()
        stats.gameHistory = [
            GameResult(won: true, turnsRemaining: 5, date: Date()),
            GameResult(won: false, turnsRemaining: 0, date: Date()),
        ]
        stats.lifetimeWins = 10
        stats.lifetimeLosses = 5
        stats.currentStreak = 3
        stats.bestStreak = 7
        stats.lastMilestone = 10

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)

        #expect(decoded.gameHistory.count == 2)
        #expect(decoded.lifetimeWins == 10)
        #expect(decoded.lifetimeLosses == 5)
        #expect(decoded.currentStreak == 3)
        #expect(decoded.bestStreak == 7)
        #expect(decoded.lastMilestone == 10)
    }

    @Test func gameResultPreservesFields() throws {
        let date = Date()
        let result = GameResult(won: true, turnsRemaining: 7, date: date)

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(GameResult.self, from: data)

        #expect(decoded.won == true)
        #expect(decoded.turnsRemaining == 7)
        #expect(abs(decoded.date.timeIntervalSince(date)) < 1)
    }

    @Test func winRateStringFormatting() {
        let stats = StatsData(
            gamesPlayed: 4,
            wins: 3,
            losses: 1,
            winRate: 75.0,
            currentStreak: 2,
            bestStreak: 3
        )
        #expect(stats.winRateString == "75.0%")
    }

    @Test func winRateStringZero() {
        let stats = StatsData(
            gamesPlayed: 0,
            wins: 0,
            losses: 0,
            winRate: 0,
            currentStreak: 0,
            bestStreak: 0
        )
        #expect(stats.winRateString == "0.0%")
    }
}
