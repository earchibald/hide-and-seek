//
//  SoundPlaying.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

protocol SoundPlaying {
    func play(for contentType: ContentType, soundEnabled: Bool, volume: Float)
    func playGameOver(soundEnabled: Bool, volume: Float)
}

extension SoundPlaying {
    func play(for contentType: ContentType, soundEnabled: Bool) {
        play(for: contentType, soundEnabled: soundEnabled, volume: 1.0)
    }
    func playGameOver(soundEnabled: Bool) {
        playGameOver(soundEnabled: soundEnabled, volume: 1.0)
    }
}
