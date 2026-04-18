import Testing
import SwiftUI
@testable import HideAndSeek

@MainActor
struct GameViewModelTests {
    private let mockSound: MockSoundManager
    private let mockStats: MockStatsTracker
    private let vm: GameViewModel

    init() {
        mockSound = MockSoundManager()
        mockStats = MockStatsTracker()
        vm = GameViewModel(soundManager: mockSound, statsTracker: mockStats, settingsStore: nil)
    }

    // MARK: - Helpers

    private func findTile(_ content: ContentType) -> Position? {
        for row in 0..<vm.GRID_SIZE {
            for col in 0..<vm.GRID_SIZE {
                if vm.board[row][col].content == content {
                    return Position(row: row, col: col)
                }
            }
        }
        return nil
    }

    private func countTiles(_ content: ContentType) -> Int {
        var count = 0
        for row in vm.board {
            for tile in row {
                if tile.content == content { count += 1 }
            }
        }
        return count
    }

    // MARK: - Game Balance Constants

    @Test func gameBalanceConstants() {
        #expect(vm.TURN_COST_TAP == -1)
        #expect(vm.TURN_BONUS_COIN == 1)
        #expect(vm.TURN_PENALTY_TRAP == -1)
        #expect(vm.TURN_PENALTY_EMPTY == 0)
        #expect(vm.GRID_SIZE == 10)
    }

    // MARK: - Board Generation

    @Test func boardIs10x10() {
        #expect(vm.board.count == 10)
        for row in vm.board {
            #expect(row.count == 10)
        }
    }

    @Test func boardHasExactlyOneFriend() {
        #expect(countTiles(.friend) == 1)
    }

    @Test func boardHasCorrectCoinCount() {
        #expect(countTiles(.coin) == vm.settings.coinCount)
    }

    @Test func boardHasCorrectTrapCount() {
        #expect(countTiles(.trap) == vm.settings.trapCount)
    }

    @Test func boardHasCorrectCompassCount() {
        #expect(countTiles(.compass) == vm.settings.compassCount)
    }

    @Test func remainingTilesAreEmpty() {
        let totalTiles = vm.GRID_SIZE * vm.GRID_SIZE
        let placedCount = 1 + vm.settings.coinCount + vm.settings.trapCount + vm.settings.compassCount
        #expect(countTiles(.empty) == totalTiles - placedCount)
    }

    // MARK: - Tile Click Behavior

    @Test func clickEmptyTile() throws {
        let pos = try #require(findTile(.empty))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 1)
        #expect(vm.feedback != nil)
        #expect(vm.feedback?.color == .gray)
    }

    @Test func clickCoinTile() throws {
        let pos = try #require(findTile(.coin))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore) // net 0: -1 tap + 1 bonus
        #expect(vm.feedback?.color == .yellow)
    }

    @Test func clickTrapTile() throws {
        let pos = try #require(findTile(.trap))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 2) // net -2: -1 tap + -1 penalty
        #expect(vm.feedback?.color == .red)
    }

    @Test func clickFriendTileWinsGame() throws {
        let pos = try #require(findTile(.friend))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.gameStatus == .won)
        #expect(vm.turns == turnsBefore - 1)
        #expect(vm.feedback?.color == .green)
        #expect(mockStats.recordedGames.count == 1)
        #expect(mockStats.recordedGames[0].won == true)
    }

    @Test func clickCompassTile() throws {
        let pos = try #require(findTile(.compass))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 1)
        #expect(vm.feedback == nil)
    }

    @Test func clickAlreadyRevealedTileHasNoEffect() throws {
        let pos = try #require(findTile(.empty))
        vm.handleTileClick(row: pos.row, col: pos.col)
        let turnsAfterFirst = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.turns == turnsAfterFirst)
    }

    @Test func clickAfterGameOverHasNoEffect() throws {
        let friendPos = try #require(findTile(.friend))
        vm.handleTileClick(row: friendPos.row, col: friendPos.col)
        #expect(vm.gameStatus == .won)

        let turnsAfterWin = vm.turns
        let emptyPos = try #require(findTile(.empty))
        vm.handleTileClick(row: emptyPos.row, col: emptyPos.col)
        #expect(vm.turns == turnsAfterWin)
        #expect(vm.board[emptyPos.row][emptyPos.col].isRevealed == false)
    }

    @Test func losingConditionWhenTurnsReachZero() throws {
        vm.turns = 2
        let trapPos = try #require(findTile(.trap))
        vm.handleTileClick(row: trapPos.row, col: trapPos.col)
        #expect(vm.gameStatus == .lost)
        #expect(mockSound.gameOverCallCount == 1)
        #expect(mockStats.recordedGames.count == 1)
        #expect(mockStats.recordedGames[0].won == false)
    }

    @Test func milestoneTriggered() throws {
        mockStats.milestoneToReturn = 10
        let friendPos = try #require(findTile(.friend))

        vm.handleTileClick(row: friendPos.row, col: friendPos.col)

        #expect(vm.celebrateMilestone == 10)
    }

    @Test func soundVolumePassthrough() throws {
        vm.settings.soundVolume = 0.5
        vm.settings.soundEnabled = true
        let pos = try #require(findTile(.empty))

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(mockSound.lastSoundEnabled == true)
        #expect(mockSound.lastVolume == 0.5)
    }

    @Test func soundDisabledPassthrough() throws {
        vm.settings.soundEnabled = false
        let pos = try #require(findTile(.empty))

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(mockSound.lastSoundEnabled == false)
    }

    // MARK: - Reset and Settings

    @Test func resetGameRestoresInitialState() throws {
        let pos = try #require(findTile(.empty))
        vm.handleTileClick(row: pos.row, col: pos.col)

        vm.resetGame()

        #expect(vm.gameStatus == .playing)
        #expect(vm.turns == vm.settings.startingTurns)
        #expect(vm.feedback == nil)
        for row in vm.board {
            for tile in row {
                #expect(tile.isRevealed == false)
            }
        }
    }

    @Test func applySettingsClosesSettingsAndResets() {
        vm.showSettings = true
        vm.applySettings()

        #expect(vm.showSettings == false)
        #expect(vm.gameStatus == .playing)
        #expect(vm.turns == vm.settings.startingTurns)
    }
}
