//
//  TileButton.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct TileButton: View {
    let tile: Tile
    var viewModel: GameViewModel

    var body: some View {
        Button(action: {
            viewModel.handleTileClick(row: tile.row, col: tile.col)
        }) {
            Text(tile.isRevealed ? tile.contentEmoji(friendPos: viewModel.friendPos) : tile.terrain.rawValue)
                .font(.title2.bold())
                .frame(width: 35, height: 35)
                .background(tile.isRevealed ? Color(red: 0.2, green: 0.45, blue: 0.2).opacity(0.7) : Color(red: 0.25, green: 0.5, blue: 0.25))
                .clipShape(.rect(cornerRadius: 6))
        }
        .disabled(tile.isRevealed || viewModel.gameStatus != .playing)
        .accessibilityLabel(tileAccessibilityLabel)
        .accessibilityHint(tile.isRevealed || viewModel.gameStatus != .playing ? "" : "Tap to reveal this tile")
    }

    private var tileAccessibilityLabel: String {
        if tile.isRevealed {
            switch tile.content {
            case .empty: "Empty tile"
            case .friend: "Friend found"
            case .coin: "Coin"
            case .trap: "Trap"
            case .compass: "Compass pointing \(tile.contentEmoji(friendPos: viewModel.friendPos))"
            }
        } else {
            "\(tile.terrain.rawValue) terrain, row \(tile.row + 1), column \(tile.col + 1)"
        }
    }
}
