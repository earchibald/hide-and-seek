//
//  StatsButtonView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct StatsButtonView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.showStats.toggle()
            }) {
                HStack {
                    Text("📊 Stats")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.showStats ? "▼" : "▶")
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
