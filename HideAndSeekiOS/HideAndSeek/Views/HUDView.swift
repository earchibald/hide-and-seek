//
//  HUDView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct HUDView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                switch viewModel.gameStatus {
                case .lost:
                    Text("💔 You Lost")
                        .font(.title3.bold())
                        .foregroundStyle(.red)
                case .won:
                    Text("🎉 You Won!")
                        .font(.title3.bold())
                        .foregroundStyle(Color(red: 0.7, green: 1.0, blue: 0.7))
                case .playing:
                    Text("Turns: \(viewModel.turns)")
                        .font(.title3.bold())
                        .foregroundStyle(viewModel.turns <= 3 ? .red : .white)
                }

                Spacer()
            }
            .padding(.horizontal)

            // Fixed height feedback area
            Group {
                switch viewModel.gameStatus {
                case .lost:
                    Text("Tap board to try again")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.9, green: 0.9, blue: 0.9))
                case .won:
                    Text("Tap board to play again")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.9, green: 0.9, blue: 0.9))
                case .playing:
                    if let feedback = viewModel.feedback {
                        Text(feedback.message)
                            .font(.headline)
                            .foregroundStyle(feedback.color)
                    } else {
                        Text(" ")
                            .font(.headline)
                    }
                }
            }
            .frame(minHeight: 28)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
