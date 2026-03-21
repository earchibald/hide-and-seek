import Foundation
@testable import HideAndSeek

@MainActor final class MockStatsTracker: StatsTracking {
    var recordedGames: [(won: Bool, turnsRemaining: Int)] = []
    var milestoneToReturn: Int? = nil

    func recordGame(won: Bool, turnsRemaining: Int) {
        recordedGames.append((won, turnsRemaining))
    }

    func checkMilestone() -> Int? {
        return milestoneToReturn
    }
}
