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
        .opacity(viewModel.gameStatus == .lost ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.gameStatus)
        .contentShape(.rect)
        .onTapGesture {
            if viewModel.gameStatus == .lost {
                viewModel.resetGame()
            }
        }
        .accessibilityLabel("Game board")
        .accessibilityHint(viewModel.gameStatus == .lost ? "Tap to try again" : "")
    }
}
