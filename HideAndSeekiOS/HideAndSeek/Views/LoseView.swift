//
//  LoseView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct LoseView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("💔 Game Over 💔")
                .font(.title2.bold())
            Text("You ran out of turns!")
                .font(.subheadline)
            Button("Try Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)
        }
        .padding()
        .background(Color(red: 0.7, green: 0.2, blue: 0.2))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
