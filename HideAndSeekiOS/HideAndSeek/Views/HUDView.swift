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
                if viewModel.gameStatus == .lost {
                    Text("💔 You Lost")
                        .font(.title3.bold())
                        .foregroundStyle(.red)
                } else {
                    Text("Turns: \(viewModel.turns)")
                        .font(.title3.bold())
                        .foregroundStyle(viewModel.turns <= 3 ? .red : .white)
                }

                Spacer()
            }
            .padding(.horizontal)

            // Fixed height feedback area
            Group {
                if viewModel.gameStatus == .lost {
                    Text("Tap board to try again")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.9, green: 0.9, blue: 0.9))
                } else if let feedback = viewModel.feedback {
                    Text(feedback.message)
                        .font(.headline)
                        .foregroundStyle(feedback.color)
                } else {
                    Text(" ")
                        .font(.headline)
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
