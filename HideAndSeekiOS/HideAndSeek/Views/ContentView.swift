//
//  ContentView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.35, blue: 0.13) // Dark green background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("🌲 Hide & Seek 🌲")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Find your friend in the wilderness!")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.7))
                }
                .padding(.top, 20)

                // HUD
                HUDView(viewModel: viewModel)

                // Win/Loss overlays
                if viewModel.gameStatus == .won {
                    WinView(viewModel: viewModel)
                }

                if viewModel.gameStatus == .lost {
                    LoseView(viewModel: viewModel)
                }

                // Grid
                GridView(viewModel: viewModel)

                // Stats Button
                StatsButtonView(viewModel: viewModel)

                // Settings Toggle
                SettingsToggleView(viewModel: viewModel)

                // Instructions
                VStack(spacing: 4) {
                    Text("Tap tiles to search for your friend 🕵️‍♀️")
                        .font(.caption2)
                    Text("All taps cost 1 turn • Coins 💰: 0 net • Traps 🕸️: -2 • Compass: -1 + hint")
                        .font(.caption2)
                }
                .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.7))
                .padding(.bottom, 10)

                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showStats) {
            StatsView(viewModel: viewModel)
        }
        .overlay {
            if let milestone = viewModel.celebrateMilestone {
                MilestoneView(milestone: milestone, viewModel: viewModel)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.revealCount) { _, _ in
            viewModel.lastRevealedContent == .empty || viewModel.lastRevealedContent == .compass
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: viewModel.revealCount) { _, _ in
            viewModel.lastRevealedContent == .coin
        }
        .sensoryFeedback(.success, trigger: viewModel.revealCount) { _, _ in
            viewModel.lastRevealedContent == .friend
        }
        .sensoryFeedback(.error, trigger: viewModel.revealCount) { _, _ in
            viewModel.lastRevealedContent == .trap
        }
        .sensoryFeedback(.error, trigger: viewModel.isGameOver)
    }
}

#Preview {
    ContentView()
}
