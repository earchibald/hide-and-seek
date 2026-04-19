//
//  GridView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct GridView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<viewModel.GRID_SIZE, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<viewModel.GRID_SIZE, id: \.self) { col in
                        TileButton(tile: viewModel.board[row][col], viewModel: viewModel)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
        .opacity(boardOpacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.gameStatus)
        .contentShape(.rect)
        .onTapGesture {
            if viewModel.gameStatus == .lost || viewModel.gameStatus == .won {
                viewModel.resetGame()
            }
        }
        .accessibilityLabel("Game board")
        .accessibilityHint(accessibilityHint)
    }

    private var boardOpacity: Double {
        switch viewModel.gameStatus {
        case .lost: return 0.5
        case .won: return 0.7
        case .playing: return 1.0
        }
    }

    private var accessibilityHint: String {
        switch viewModel.gameStatus {
        case .lost: return "Tap to try again"
        case .won: return "Tap to play again"
        case .playing: return ""
        }
    }
}
