//
//  ContentView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.35, blue: 0.13) // Dark green background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("🌲 Hide & Seek 🌲")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Find your friend in the wilderness!")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.7))
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
                
                // Settings Toggle
                SettingsView(viewModel: viewModel)
                
                // Instructions
                VStack(spacing: 4) {
                    Text("Tap tiles to search for your friend 🕵️‍♀️")
                        .font(.system(size: 11))
                    Text("All taps cost 1 turn • Coins 💰: 0 net • Traps 🕸️: -2 • Compass: -1 + hint")
                        .font(.system(size: 11))
                }
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.7))
                .padding(.bottom, 10)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsSheetView(viewModel: viewModel)
        }
    }
}

struct HUDView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Turns: ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                +
                Text("\(viewModel.turns)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(viewModel.turns <= 3 ? .red : .white)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Fixed height feedback area
            Group {
                if let feedback = viewModel.feedback {
                    Text(feedback.message)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(feedback.color)
                } else {
                    Text(" ")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .frame(minHeight: 28)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct GridView: View {
    @ObservedObject var viewModel: GameViewModel
    
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
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct TileButton: View {
    let tile: Tile
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        Button(action: {
            viewModel.handleTileClick(row: tile.row, col: tile.col)
        }) {
            Text(tile.isRevealed ? tile.contentEmoji(friendPos: viewModel.friendPos) : tile.terrain.rawValue)
                .font(.system(size: 20))
                .frame(width: 35, height: 35)
                .background(tile.isRevealed ? Color(red: 0.2, green: 0.45, blue: 0.2).opacity(0.7) : Color(red: 0.25, green: 0.5, blue: 0.25))
                .cornerRadius(6)
        }
        .disabled(tile.isRevealed || viewModel.gameStatus != .playing)
    }
}

struct WinView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🎉 Victory! 🎉")
                .font(.system(size: 24, weight: .bold))
            Text("You found your friend with \(viewModel.turns) turns remaining!")
                .font(.system(size: 16))
            Button("Play Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
        }
        .padding()
        .background(Color(red: 0.25, green: 0.6, blue: 0.25))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct LoseView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("💔 Game Over 💔")
                .font(.system(size: 24, weight: .bold))
            Text("You ran out of turns!")
                .font(.system(size: 16))
            Button("Try Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
        }
        .padding()
        .background(Color(red: 0.7, green: 0.2, blue: 0.2))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.showSettings.toggle()
            }) {
                HStack {
                    Text("⚙️ Settings / Debug")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text(viewModel.showSettings ? "▼" : "▶")
                }
                .foregroundColor(.white)
                .padding()
            }
        }
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct SettingsSheetView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Settings")) {
                    VStack(alignment: .leading) {
                        Text("Starting Turns: \(viewModel.settings.startingTurns)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.startingTurns) },
                            set: { viewModel.settings.startingTurns = Int($0) }
                        ), in: 5...30, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Trap Count: \(viewModel.settings.trapCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.trapCount) },
                            set: { viewModel.settings.trapCount = Int($0) }
                        ), in: 0...20, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Coin Count: \(viewModel.settings.coinCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.coinCount) },
                            set: { viewModel.settings.coinCount = Int($0) }
                        ), in: 0...20, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Compass Count: \(viewModel.settings.compassCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.compassCount) },
                            set: { viewModel.settings.compassCount = Int($0) }
                        ), in: 0...15, step: 1)
                    }
                }
                
                Section {
                    Button("Apply & Reset Game") {
                        viewModel.applySettings()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
