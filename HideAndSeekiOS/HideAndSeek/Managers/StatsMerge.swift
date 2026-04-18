import Foundation

enum StatsMerge {
    /// Merge a local and remote `GameStats` using domain-level rules:
    /// - lifetime counters and `bestStreak` take the max
    /// - `currentStreak` stays local (device-scoped concept)
    /// - `lastMilestone` takes the max
    /// - `gameHistory` is unioned by identity, sorted by date, trimmed to `historyLimit`
    static func merge(local: GameStats, remote: GameStats, historyLimit: Int = 100) -> GameStats {
        var merged = GameStats()
        merged.lifetimeWins = max(local.lifetimeWins, remote.lifetimeWins)
        merged.lifetimeLosses = max(local.lifetimeLosses, remote.lifetimeLosses)
        merged.bestStreak = max(local.bestStreak, remote.bestStreak)
        merged.currentStreak = local.currentStreak
        switch (local.lastMilestone, remote.lastMilestone) {
        case let (l?, r?): merged.lastMilestone = max(l, r)
        case let (l?, nil): merged.lastMilestone = l
        case let (nil, r?): merged.lastMilestone = r
        case (nil, nil): merged.lastMilestone = nil
        }

        var seen = Set<GameResult>()
        var combined: [GameResult] = []
        for result in local.gameHistory + remote.gameHistory where seen.insert(result).inserted {
            combined.append(result)
        }
        combined.sort { $0.date < $1.date }
        if combined.count > historyLimit {
            combined.removeFirst(combined.count - historyLimit)
        }
        merged.gameHistory = combined
        return merged
    }
}
