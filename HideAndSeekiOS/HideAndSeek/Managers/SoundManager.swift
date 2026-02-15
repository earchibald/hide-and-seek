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

        // Play sound on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            switch contentType {
            case .empty:
                AudioServicesPlaySystemSound(1103)

            case .trap:
                AudioServicesPlaySystemSound(1053)

            case .coin:
                AudioServicesPlaySystemSound(1013)

            case .friend:
                AudioServicesPlaySystemSound(1111)

            case .compass:
                AudioServicesPlaySystemSound(1057)
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
