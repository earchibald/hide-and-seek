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

    private init() {
        // Prepare generators for better performance
        lightImpact.prepare()
        mediumImpact.prepare()
        notificationFeedback.prepare()
    }

    /// Play sound and haptic feedback for a tile content type
    func play(for contentType: ContentType, soundEnabled: Bool) {
        guard soundEnabled else { return }

        switch contentType {
        case .empty:
            playSound(named: "shovel", systemSoundID: 1104)
            lightImpact.impactOccurred()

        case .trap:
            playSound(named: "buzzer", systemSoundID: 1053)
            notificationFeedback.notificationOccurred(.error)

        case .coin:
            playSound(named: "coins", systemSoundID: 1102)
            mediumImpact.impactOccurred()

        case .friend:
            playSound(named: "victory", systemSoundID: 1111)
            notificationFeedback.notificationOccurred(.success)

        case .compass:
            playSound(named: "compass", systemSoundID: 1057)
            lightImpact.impactOccurred()
        }
    }

    /// Play custom sound file if available, otherwise fall back to system sound
    private func playSound(named soundName: String, systemSoundID: SystemSoundID) {
        // Try to play custom sound file first
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") ??
                     Bundle.main.url(forResource: soundName, withExtension: "caf") {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
            return
        }

        // Fall back to system sound
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
