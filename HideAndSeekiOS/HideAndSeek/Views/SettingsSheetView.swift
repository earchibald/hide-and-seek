//
//  SettingsSheetView.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

struct SettingsSheetView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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

                Section(header: Text("Audio")) {
                    Toggle("Sound Effects", isOn: $viewModel.settings.soundEnabled)

                    VStack(alignment: .leading) {
                        Text("Volume Boost: \(String(format: "%.1fx", viewModel.settings.soundVolume))")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.soundVolume) },
                            set: { viewModel.settings.soundVolume = Float($0) }
                        ), in: 0.5...10.0, step: 0.5)
                    }
                }

                Section {
                    Button("Apply & Reset Game") {
                        viewModel.applySettings()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
