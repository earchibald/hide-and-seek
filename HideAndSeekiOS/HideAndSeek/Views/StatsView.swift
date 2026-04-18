//
//  StatsView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct StatsView: View {
    var viewModel: GameViewModel
    var statsManager: StatsManager = .shared
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirmation = false
    @State private var showRestoreSheet = false
    @State private var restoreWins = ""
    @State private var restoreLosses = ""
    @State private var restoreCurrentStreak = ""
    @State private var restoreBestStreak = ""
    @State private var restoreLastMilestone = ""
    @State private var refreshToken = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Lifetime Stats
                    StatsSectionView(
                        title: "LIFETIME STATS",
                        stats: statsManager.getLifetimeStats()
                    )

                    // Last 10 Games
                    StatsSectionView(
                        title: "LAST 10 GAMES",
                        stats: statsManager.getLast10Stats()
                    )

                    // Last 100 Games
                    StatsSectionView(
                        title: "LAST 100 GAMES",
                        stats: statsManager.getLast100Stats()
                    )

                    // Clear Stats Button
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        Text("Clear All Stats")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    Button("Restore from old version") {
                        showRestoreSheet = true
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 4)
                }
                .id(refreshToken)
                .padding(.vertical)
            }
            .background(Color(red: 0.13, green: 0.35, blue: 0.13))
            .navigationTitle("Player Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .alert("Clear All Statistics?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    statsManager.clearStats()
                    refreshToken &+= 1
                }
            } message: {
                Text("This will permanently delete all your game statistics. This cannot be undone.")
            }
            .sheet(isPresented: $showRestoreSheet) {
                RestoreStatsSheet(
                    wins: $restoreWins,
                    losses: $restoreLosses,
                    currentStreak: $restoreCurrentStreak,
                    bestStreak: $restoreBestStreak,
                    lastMilestone: $restoreLastMilestone,
                    onApply: {
                        let wins = Int(restoreWins) ?? 0
                        let losses = Int(restoreLosses) ?? 0
                        let current = Int(restoreCurrentStreak) ?? 0
                        let best = Int(restoreBestStreak) ?? 0
                        let milestone = restoreLastMilestone.isEmpty ? nil : Int(restoreLastMilestone)
                        statsManager.restore(
                            wins: wins,
                            losses: losses,
                            currentStreak: current,
                            bestStreak: best,
                            lastMilestone: milestone
                        )
                        refreshToken &+= 1
                        showRestoreSheet = false
                    }
                )
            }
        }
    }
}

struct RestoreStatsSheet: View {
    @Binding var wins: String
    @Binding var losses: String
    @Binding var currentStreak: String
    @Binding var bestStreak: String
    @Binding var lastMilestone: String
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Wins") {
                        TextField("0", text: $wins)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Losses") {
                        TextField("0", text: $losses)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Current Streak") {
                        TextField("0", text: $currentStreak)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Best Streak") {
                        TextField("0", text: $bestStreak)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Last Milestone") {
                        TextField("none", text: $lastMilestone)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Enter totals from your previous install")
                } footer: {
                    Text("Overwrites current stats. Leaves game history empty; last-10 / last-100 windows will refill as you play.")
                }
            }
            .navigationTitle("Restore Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore", action: onApply).bold()
                }
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
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.7))
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                HStack {
                    Text("Games Played:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(stats.gamesPlayed)")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Wins:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(stats.wins)")
                        .foregroundStyle(.green)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Losses:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(stats.losses)")
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Win Rate:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(stats.winRateString)
                        .foregroundStyle(.yellow)
                        .fontWeight(.bold)
                }

                Divider()
                    .background(Color(red: 0.7, green: 0.9, blue: 0.7).opacity(0.3))

                HStack {
                    Text("Current Streak:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(stats.currentStreak)")
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Best Streak:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(stats.bestStreak)")
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}
