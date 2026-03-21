import Foundation
@testable import HideAndSeek

final class MockSoundManager: SoundPlaying {
    var playCallCount = 0
    var lastPlayedContentType: ContentType?
    var lastSoundEnabled: Bool?
    var lastVolume: Float?
    var gameOverCallCount = 0

    func play(for contentType: ContentType, soundEnabled: Bool, volume: Float) {
        playCallCount += 1
        lastPlayedContentType = contentType
        lastSoundEnabled = soundEnabled
        lastVolume = volume
    }

    func playGameOver(soundEnabled: Bool, volume: Float) {
        gameOverCallCount += 1
    }
}
