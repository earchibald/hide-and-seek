//
//  WinView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct WinView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("🎉 Victory! 🎉")
                .font(.title2.bold())
            Text("You found your friend with \(viewModel.turns) turns remaining!")
                .font(.subheadline)
            Button("Play Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)

            Button("Show Stats") {
                viewModel.showStats = true
            }
            .padding()
            .background(Color(red: 0.2, green: 0.45, blue: 0.2))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)
        }
        .padding()
        .background(Color(red: 0.25, green: 0.6, blue: 0.25))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
