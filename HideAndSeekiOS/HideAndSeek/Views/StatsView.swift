//
//  StatsView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct StatsView: View {
    var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Lifetime Stats
                    StatsSectionView(
                        title: "LIFETIME STATS",
                        stats: StatsManager.shared.getLifetimeStats()
                    )

                    // Last 10 Games
                    StatsSectionView(
                        title: "LAST 10 GAMES",
                        stats: StatsManager.shared.getLast10Stats()
                    )

                    // Last 100 Games
                    StatsSectionView(
                        title: "LAST 100 GAMES",
                        stats: StatsManager.shared.getLast100Stats()
                    )

                    // Clear Stats Button
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        Text("Clear All Stats")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.13, green: 0.35, blue: 0.13))
            .navigationTitle("Player Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Clear All Statistics?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    StatsManager.shared.clearStats()
                }
            } message: {
                Text("This will permanently delete all your game statistics. This cannot be undone.")
            }
        }
    }
}

struct StatsSectionView: View {
    let title: String
    let stats: StatsData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.7))
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                HStack {
                    Text("Games Played:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.gamesPlayed)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Wins:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.wins)")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Losses:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.losses)")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Win Rate:")
                        .foregroundColor(.white)
                    Spacer()
                    Text(stats.winRateString)
                        .foregroundColor(.yellow)
                        .fontWeight(.bold)
                }

                Divider()
                    .background(Color(red: 0.7, green: 0.9, blue: 0.7).opacity(0.3))

                HStack {
                    Text("Current Streak:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.currentStreak)")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Best Streak:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.bestStreak)")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 15))
        }
        .padding()
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}
