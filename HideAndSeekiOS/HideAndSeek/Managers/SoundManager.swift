//
//  SoundManager.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()

    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Pre-loaded sound IDs
    private var soundIDs: [String: SystemSoundID] = [:]

    private init() {
        // Prepare generators for better performance
        lightImpact.prepare()
        mediumImpact.prepare()
        notificationFeedback.prepare()

        // Pre-load all sound files
        loadSound(named: "shovel")
        loadSound(named: "buzzer")
        loadSound(named: "coins")
        loadSound(named: "victory")
        loadSound(named: "compass")
    }

    private func loadSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            return
        }

        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        soundIDs[soundName] = soundID
    }

    /// Play sound and haptic feedback for a tile content type
    func play(for contentType: ContentType, soundEnabled: Bool) {
        guard soundEnabled else { return }

        // Play sound on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

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

            if let soundID = self.soundIDs[soundName] {
                AudioServicesPlaySystemSound(soundID)
            }
        }

        // Play haptics on main queue (required for haptics)
        playHaptic(for: contentType)
    }

    private func playHaptic(for contentType: ContentType) {
        switch contentType {
        case .empty:
            lightImpact.impactOccurred()

        case .trap:
            notificationFeedback.notificationOccurred(.error)

        case .coin:
            mediumImpact.impactOccurred()

        case .friend:
            notificationFeedback.notificationOccurred(.success)

        case .compass:
            lightImpact.impactOccurred()
        }
    }
}
