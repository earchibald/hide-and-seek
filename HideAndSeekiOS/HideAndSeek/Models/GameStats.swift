//
//  GameStats.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

/// Represents a single game result
struct GameResult: Codable {
    let won: Bool
    let turnsRemaining: Int
    let date: Date
}

/// Main stats data structure for persistence
struct GameStats: Codable {
    var gameHistory: [GameResult] = []
    var lifetimeWins: Int = 0
    var lifetimeLosses: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastMilestone: Int? = nil

    init() {}
}

/// Calculated stats for display
struct StatsData {
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let currentStreak: Int
    let bestStreak: Int

    var winRateString: String {
        return String(format: "%.1f%%", winRate)
    }
}
