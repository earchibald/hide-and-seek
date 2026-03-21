//
//  StatsTracking.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

@MainActor protocol StatsTracking {
    func recordGame(won: Bool, turnsRemaining: Int)
    func checkMilestone() -> Int?
}
