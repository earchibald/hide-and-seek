//
//  GameViewModel.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation
import SwiftUI

enum GameStatus {
    case playing
    case won
    case lost
}

struct FeedbackMessage: Identifiable {
    let id = UUID()
    let message: String
    let color: Color
}

class GameViewModel: ObservableObject {
    // Game balance constants
    let TURN_COST_TAP = -1
    let TURN_BONUS_COIN = 1
    let TURN_PENALTY_TRAP = -1
    let TURN_PENALTY_EMPTY = 0
    let GRID_SIZE = 10
    
    @Published var settings = GameSettings()
    @Published var board: [[Tile]] = []
    @Published var turns: Int = 15
    @Published var gameStatus: GameStatus = .playing
    @Published var friendPos: Position?
    @Published var feedback: FeedbackMessage?
    @Published var showSettings = false
    
    init() {
        generateBoard()
        turns = settings.startingTurns
    }
    
    func generateBoard() {
        var newBoard: [[Tile]] = []
        let terrainTypes = TerrainType.allCases
        let terrainWeights = [60, 20, 15, 5] // Percentage weights
        
        // Initialize grid
        for row in 0..<GRID_SIZE {
            var boardRow: [Tile] = []
            for col in 0..<GRID_SIZE {
                // Random terrain based on weights
                let rand = Int.random(in: 0..<100)
                var terrain = TerrainType.grass
                var cumulative = 0
                
                for (index, weight) in terrainWeights.enumerated() {
                    cumulative += weight
                    if rand < cumulative {
                        terrain = terrainTypes[index]
                        break
                    }
                }
                
                let tile = Tile(row: row, col: col, terrain: terrain, content: .empty)
                boardRow.append(tile)
            }
            newBoard.append(boardRow)
        }
        
        // Place hidden content
        var availablePositions: [Position] = []
        for row in 0..<GRID_SIZE {
            for col in 0..<GRID_SIZE {
                availablePositions.append(Position(row: row, col: col))
            }
        }
        availablePositions.shuffle()
        
        // Place 1 friend
        let friendPosition = availablePositions[0]
        newBoard[friendPosition.row][friendPosition.col].content = .friend
        friendPos = friendPosition
        
        // Place coins
        for i in 1...min(settings.coinCount, availablePositions.count - 1) {
            let pos = availablePositions[i]
            newBoard[pos.row][pos.col].content = .coin
        }
        
        // Place traps
        let trapEnd = min(1 + settings.coinCount + settings.trapCount, availablePositions.count)
        for i in (1 + settings.coinCount)..<trapEnd {
            let pos = availablePositions[i]
            newBoard[pos.row][pos.col].content = .trap
        }
        
        // Place compasses
        let compassEnd = min(1 + settings.coinCount + settings.trapCount + settings.compassCount, availablePositions.count)
        for i in (1 + settings.coinCount + settings.trapCount)..<compassEnd {
            let pos = availablePositions[i]
            newBoard[pos.row][pos.col].content = .compass
        }
        
        board = newBoard
    }
    
    func handleTileClick(row: Int, col: Int) {
        guard gameStatus == .playing else { return }
        guard !board[row][col].isRevealed else { return }
        
        board[row][col].isRevealed = true
        let tile = board[row][col]
        
        var turnChange = TURN_COST_TAP
        var message = ""
        var feedbackColor = Color.gray
        
        switch tile.content {
        case .friend:
            gameStatus = .won
            message = "You found the Friend! 🎉"
            feedbackColor = .green
            
        case .coin:
            turnChange += TURN_BONUS_COIN
            message = "Coin! (\(turnChange) Turn\(abs(turnChange) != 1 ? "s" : ""))"
            feedbackColor = .yellow
            
        case .trap:
            turnChange += TURN_PENALTY_TRAP
            message = "Trap! (\(turnChange) Turn\(abs(turnChange) != 1 ? "s" : ""))"
            feedbackColor = .red
            
        case .compass:
            // No feedback message for compass
            break
            
        case .empty:
            turnChange += TURN_PENALTY_EMPTY
            message = "Empty (\(turnChange) Turn\(abs(turnChange) != 1 ? "s" : ""))"
            feedbackColor = .gray
        }
        
        turns += turnChange
        
        if tile.content != .friend && turns <= 0 {
            gameStatus = .lost
        }
        
        if !message.isEmpty {
            feedback = FeedbackMessage(message: message, color: feedbackColor)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.feedback = nil
            }
        }
    }
    
    func resetGame() {
        generateBoard()
        turns = settings.startingTurns
        gameStatus = .playing
        feedback = nil
    }
    
    func applySettings() {
        showSettings = false
        resetGame()
    }
}
