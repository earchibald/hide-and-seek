//
//  SoundManager.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import AVFoundation

@MainActor class SoundManager: SoundPlaying {
    static let shared = SoundManager()

    // Audio players for each sound
    private var audioPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        // Configure audio session for maximum volume
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        // Pre-load all sound files
        loadSound(named: "shovel")
        loadSound(named: "buzzer")
        loadSound(named: "coins")
        loadSound(named: "victory")
        loadSound(named: "compass")
        loadSound(named: "failure")
    }

    private func loadSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            print("Could not find sound: \(soundName).wav")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0  // Maximum volume
            player.prepareToPlay()
            audioPlayers[soundName] = player
        } catch {
            print("Failed to load sound \(soundName): \(error)")
        }
    }

    /// Play sound for a tile content type
    func play(for contentType: ContentType, soundEnabled: Bool, volume: Float = 1.0) {
        guard soundEnabled else { return }

        // Play sound
        let soundName: String
        switch contentType {
        case .empty:
            soundName = "shovel"
        case .trap:
            soundName = "buzzer"
        case .coin:
            soundName = "coins"
        case .friend:
            soundName = "victory"
        case .compass:
            soundName = "compass"
        }

        if let player = audioPlayers[soundName] {
            player.volume = min(volume, 10.0)  // Allow boost up to 10x
            player.currentTime = 0  // Reset to beginning
            player.play()
        }
    }

    /// Play game over sound when player loses
    func playGameOver(soundEnabled: Bool, volume: Float = 1.0) {
        guard soundEnabled else { return }

        if let player = audioPlayers["failure"] {
            player.volume = min(volume, 10.0)
            player.currentTime = 0
            player.play()
        }
    }
}
