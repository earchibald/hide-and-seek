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
                Text("🏆")
                    .font(.system(size: 80))
                    .scaleEffect(showAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showAnimation)

                // Title
                Text("Milestone Achieved!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                // Milestone number
                Text("\(milestone) Wins!")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(.yellow)

                Spacer()
                    .frame(height: 20)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.showStats = true
                        viewModel.celebrateMilestone = nil
                    }) {
                        Text("Show Stats")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        viewModel.celebrateMilestone = nil
                    }) {
                        Text("Continue Playing")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 320)
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .cornerRadius(20)
            .shadow(radius: 10)
            .opacity(showAnimation ? 1.0 : 0)
            .animation(.easeIn(duration: 0.3), value: showAnimation)
        }
        .onAppear {
            showAnimation = true
        }
    }
}
