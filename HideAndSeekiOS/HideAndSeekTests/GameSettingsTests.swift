import Testing
@testable import HideAndSeek

struct GameSettingsTests {
    @Test func defaultValues() {
        let settings = GameSettings()
        #expect(settings.startingTurns == 15)
        #expect(settings.trapCount == 10)
        #expect(settings.coinCount == 10)
        #expect(settings.compassCount == 5)
        #expect(settings.soundEnabled == true)
        #expect(settings.soundVolume == 1.0)
    }

    @Test func settingsAreMutable() {
        var settings = GameSettings()
        settings.startingTurns = 20
        settings.trapCount = 5
        settings.coinCount = 15
        settings.compassCount = 3
        settings.soundEnabled = false
        settings.soundVolume = 0.5

        #expect(settings.startingTurns == 20)
        #expect(settings.trapCount == 5)
        #expect(settings.coinCount == 15)
        #expect(settings.compassCount == 3)
        #expect(settings.soundEnabled == false)
        #expect(settings.soundVolume == 0.5)
    }
}
