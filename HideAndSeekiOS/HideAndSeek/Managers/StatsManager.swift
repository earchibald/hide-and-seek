//
//  StatsManager.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

class StatsManager {
    static let shared = StatsManager()

    private let userDefaultsKey = "hideAndSeek.playerStats"
    private let maxHistorySize = 100
    private let milestones = [10, 25, 50, 100, 500]

    private var stats: GameStats

    private init() {
        // Load existing stats or create new
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameStats.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = GameStats()
            saveStats()
        }
    }

    /// Record a completed game
    func recordGame(won: Bool, turnsRemaining: Int) {
        let result = GameResult(won: won, turnsRemaining: turnsRemaining, date: Date())

        // Add to history (keep last 100)
        stats.gameHistory.append(result)
        if stats.gameHistory.count > maxHistorySize {
            stats.gameHistory.removeFirst()
        }

        // Update lifetime stats
        if won {
            stats.lifetimeWins += 1
            stats.currentStreak += 1
            if stats.currentStreak > stats.bestStreak {
                stats.bestStreak = stats.currentStreak
            }
        } else {
            stats.lifetimeLosses += 1
            stats.currentStreak = 0
        }

        saveStats()
    }

    /// Check if a milestone was just reached (returns milestone number if new)
    func checkMilestone() -> Int? {
        let wins = stats.lifetimeWins

        // Find highest milestone reached
        var reachedMilestone: Int? = nil
        for milestone in milestones {
            if wins >= milestone {
                reachedMilestone = milestone
            }
        }

        // Only return if it's a NEW milestone
        if let milestone = reachedMilestone {
            if stats.lastMilestone == nil || milestone > stats.lastMilestone! {
                stats.lastMilestone = milestone
                saveStats()
                return milestone
            }
        }

        return nil
    }

    /// Get lifetime statistics
    func getLifetimeStats() -> StatsData {
        let totalGames = stats.lifetimeWins + stats.lifetimeLosses
        let winRate = totalGames > 0 ? Double(stats.lifetimeWins) / Double(totalGames) * 100 : 0

        return StatsData(
            gamesPlayed: totalGames,
            wins: stats.lifetimeWins,
            losses: stats.lifetimeLosses,
            winRate: winRate,
            currentStreak: stats.currentStreak,
            bestStreak: stats.bestStreak
        )
    }

    /// Get stats for last N games
    private func getRecentStats(count: Int) -> StatsData {
        let recentGames = Array(stats.gameHistory.suffix(count))
        let wins = recentGames.filter { $0.won }.count
        let losses = recentGames.count - wins
        let winRate = recentGames.count > 0 ? Double(wins) / Double(recentGames.count) * 100 : 0

        // Calculate current streak from recent games
        var currentStreak = 0
        for game in recentGames.reversed() {
            if game.won {
                currentStreak += 1
            } else {
                break
            }
        }

        // Calculate best streak in this window
        var bestStreak = 0
        var tempStreak = 0
        for game in recentGames {
            if game.won {
                tempStreak += 1
                bestStreak = max(bestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }

        return StatsData(
            gamesPlayed: recentGames.count,
            wins: wins,
            losses: losses,
            winRate: winRate,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }

    /// Get last 10 games statistics
    func getLast10Stats() -> StatsData {
        return getRecentStats(count: 10)
    }

    /// Get last 100 games statistics
    func getLast100Stats() -> StatsData {
        return getRecentStats(count: 100)
    }

    /// Clear all statistics
    func clearStats() {
        stats = GameStats()
        saveStats()
    }

    /// Save stats to UserDefaults
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}
