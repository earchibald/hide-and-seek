//
//  MilestoneView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct MilestoneView: View {
    let milestone: Int
    var viewModel: GameViewModel
    @State private var showAnimation = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent accidental dismissal
                }

            // Celebration card
            VStack(spacing: 20) {
                // Trophy
                Text("\u{1F3C6}")
                    .font(.system(size: 80))
                    .scaleEffect(showAnimation ? 1.0 : (reduceMotion ? 1.0 : 0.5))
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: showAnimation)

                // Title
                Text("Milestone Achieved!")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                // Milestone number
                Text("\(milestone) Wins!")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.yellow)

                Spacer()
                    .frame(height: 20)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.showStats = true
                        viewModel.celebrateMilestone = nil
                    }) {
                        Text("Show Stats")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(.rect(cornerRadius: 10))
                    }

                    Button(action: {
                        viewModel.celebrateMilestone = nil
                    }) {
                        Text("Continue Playing")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 320)
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .clipShape(.rect(cornerRadius: 20))
            .shadow(radius: 10)
            .opacity(showAnimation ? 1.0 : 0)
            .animation(.easeIn(duration: reduceMotion ? 0 : 0.3), value: showAnimation)
        }
        .onAppear {
            showAnimation = true
        }
    }
}
