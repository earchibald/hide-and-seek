//
//  StatsManager.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

@MainActor class StatsManager: StatsTracking {
    static let shared = StatsManager()

    private let defaults: UserDefaults
    private let cloud: CloudStoring
    private let userDefaultsKey = "hideAndSeek.playerStats"
    private let maxHistorySize = 100
    private let milestones = [10, 25, 50, 100, 500]

    private var stats: GameStats

    private convenience init() {
        self.init(defaults: .standard, cloud: CloudStore.shared)
    }

    init(defaults: UserDefaults, cloud: CloudStoring = NoOpCloudStore()) {
        self.defaults = defaults
        self.cloud = cloud

        let local: GameStats
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameStats.self, from: data) {
            local = decoded
        } else {
            local = GameStats()
        }

        if let remote = cloud.load(GameStats.self, forKey: CloudKeys.stats) {
            self.stats = StatsMerge.merge(local: local, remote: remote, historyLimit: maxHistorySize)
        } else {
            self.stats = local
        }
        persist()

        cloud.addExternalChangeObserver { [weak self] keys in
            guard let self, keys.contains(CloudKeys.stats) else { return }
            self.mergeRemote()
        }
    }

    /// Record a completed game
    func recordGame(won: Bool, turnsRemaining: Int) {
        let result = GameResult(won: won, turnsRemaining: turnsRemaining, date: Date())

        stats.gameHistory.append(result)
        if stats.gameHistory.count > maxHistorySize {
            stats.gameHistory.removeFirst()
        }

        if won {
            stats.lifetimeWins += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)
        } else {
            stats.lifetimeLosses += 1
            stats.currentStreak = 0
        }

        persist()
    }

    /// Check if a milestone was just reached (returns milestone number if new)
    func checkMilestone() -> Int? {
        let wins = stats.lifetimeWins

        var reachedMilestone: Int? = nil
        for milestone in milestones where wins >= milestone {
            reachedMilestone = milestone
        }

        if let milestone = reachedMilestone {
            if stats.lastMilestone == nil || milestone > stats.lastMilestone! {
                stats.lastMilestone = milestone
                persist()
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

        var currentStreak = 0
        for game in recentGames.reversed() {
            if game.won { currentStreak += 1 } else { break }
        }

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
        persist()
    }

    /// One-shot restore from a previous install. Overwrites lifetime counters
    /// and streaks; leaves `gameHistory` empty (the last-10/last-100 windows
    /// will refill naturally).
    func restore(wins: Int, losses: Int, currentStreak: Int, bestStreak: Int, lastMilestone: Int?) {
        var new = GameStats()
        new.lifetimeWins = wins
        new.lifetimeLosses = losses
        new.currentStreak = currentStreak
        new.bestStreak = bestStreak
        new.lastMilestone = lastMilestone
        stats = new
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(stats) {
            defaults.set(encoded, forKey: userDefaultsKey)
        }
        cloud.save(stats, forKey: CloudKeys.stats)
    }

    private func mergeRemote() {
        guard let remote = cloud.load(GameStats.self, forKey: CloudKeys.stats) else { return }
        stats = StatsMerge.merge(local: stats, remote: remote, historyLimit: maxHistorySize)
        if let encoded = try? JSONEncoder().encode(stats) {
            defaults.set(encoded, forKey: userDefaultsKey)
        }
    }
}
