# Swift Testing Suite Design — Hide & Seek iOS

**Date:** 2026-03-21
**Status:** Draft

## Overview

Add a comprehensive Swift Testing test suite to the Hide & Seek iOS game. The codebase currently has zero test coverage. This spec covers production code refactoring for testability, test infrastructure, and full test coverage across all layers.

## Decisions

- **Framework:** Swift Testing (not XCTest). Struct-based test suites, `#expect`/`#require` assertions, `@Test(arguments:)` for parameterized tests.
- **Refactoring level:** Full — protocol-based DI for `SoundManager` and `StatsManager`, injectable `UserDefaults` for persistence testing.
- **Coverage strategy:** Deep and complete — all layers, edge cases, boundary conditions.
- **SoundManager testing:** Protocol + mock only. No testing of `SoundManager` internals (thin wrapper over system frameworks).
- **Compass tests:** Parameterized via `@Test(arguments:)`.
- **File organization:** One test file per source file, mirroring source structure.

## Section 1: Production Code Refactoring

### New Protocols

Two new protocol files in `HideAndSeek/Managers/`:

**`SoundPlaying.swift`**

```swift
protocol SoundPlaying {
    func play(for contentType: ContentType, soundEnabled: Bool, volume: Float)
    func playGameOver(soundEnabled: Bool, volume: Float)
}
```

**`StatsTracking.swift`**

```swift
protocol StatsTracking {
    func recordGame(won: Bool, turnsRemaining: Int)
    func checkMilestone() -> Int?
}
```

### Conformances

- `SoundManager: SoundPlaying` — methods already match, just add conformance.
- `StatsManager: StatsTracking` — methods already match, just add conformance.

### GameViewModel Dependency Injection

Change `GameViewModel.init` to accept dependencies with defaults:

```swift
class GameViewModel: ObservableObject {
    let soundManager: SoundPlaying
    let statsTracker: StatsTracking

    init(soundManager: SoundPlaying = SoundManager.shared,
         statsTracker: StatsTracking = StatsManager.shared) {
        self.soundManager = soundManager
        self.statsTracker = statsTracker
        generateBoard()
        turns = settings.startingTurns
    }
}
```

Replace all `SoundManager.shared` and `StatsManager.shared` calls inside `handleTileClick` with `self.soundManager` and `self.statsTracker`.

### StatsManager Testable Init

Add a non-private initializer accepting a `UserDefaults` instance:

```swift
class StatsManager: StatsTracking {
    static let shared = StatsManager()

    private let defaults: UserDefaults
    private let userDefaultsKey = "hideAndSeek.playerStats"

    private convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameStats.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = GameStats()
            saveStats()
        }
    }
}
```

All internal `UserDefaults.standard` references change to `self.defaults`.

## Section 2: Test Target & File Structure

### Xcode Target

New test target: `HideAndSeekTests`, using Swift Testing. Added to `HideAndSeek.xcodeproj`.

### File Layout

```
HideAndSeekiOS/
├── HideAndSeekTests/
│   ├── Mocks/
│   │   ├── MockSoundManager.swift
│   │   └── MockStatsTracker.swift
│   ├── TileTests.swift
│   ├── GameSettingsTests.swift
│   ├── GameStatsTests.swift
│   ├── GameViewModelTests.swift
│   └── StatsManagerTests.swift
```

### Mocks

**`MockSoundManager.swift`**

```swift
final class MockSoundManager: SoundPlaying {
    var playCallCount = 0
    var lastPlayedContentType: ContentType?
    var gameOverCallCount = 0

    func play(for contentType: ContentType, soundEnabled: Bool, volume: Float) {
        playCallCount += 1
        lastPlayedContentType = contentType
    }

    func playGameOver(soundEnabled: Bool, volume: Float) {
        gameOverCallCount += 1
    }
}
```

**`MockStatsTracker.swift`**

```swift
final class MockStatsTracker: StatsTracking {
    var recordedGames: [(won: Bool, turnsRemaining: Int)] = []
    var milestoneToReturn: Int? = nil

    func recordGame(won: Bool, turnsRemaining: Int) {
        recordedGames.append((won, turnsRemaining))
    }

    func checkMilestone() -> Int? {
        return milestoneToReturn
    }
}
```

## Section 3: Test Coverage Plan

### TileTests.swift

| Test | Description |
|------|-------------|
| Parameterized compass directions | All 8 directions (N, NE, E, SE, S, SW, W, NW) via `@Test(arguments:)` |
| Compass edge case — same position | Tile at same position as friend |
| `contentEmoji` per ContentType | Returns correct emoji for friend, coin, trap, empty |
| `contentEmoji` for compass | Returns directional arrow |
| Default `isRevealed` | Initializes to `false` |

### GameSettingsTests.swift

| Test | Description |
|------|-------------|
| Default values | 15 turns, 10 traps, 10 coins, 5 compasses, sound on, volume 1.0 |
| Mutability | Settings fields can be changed |

### GameStatsTests.swift

| Test | Description |
|------|-------------|
| Empty GameStats round-trip | Encodes/decodes correctly |
| Populated GameStats round-trip | History, wins, losses, streaks survive JSON |
| GameResult preserves fields | All fields survive encoding |
| `winRateString` formatting | e.g., `"75.0%"` |

### GameViewModelTests.swift

| Test | Description |
|------|-------------|
| Board is 10x10 | Grid dimensions |
| Exactly 1 friend placed | Content count validation |
| Correct coin/trap/compass counts | Match settings |
| Remaining tiles are empty | Board generation invariant |
| Click empty tile | Reveals, costs 1 turn, gray feedback |
| Click coin tile | Reveals, net 0 turn change, yellow feedback |
| Click trap tile | Reveals, costs 2 turns, red feedback |
| Click friend tile | Sets `.won`, records win, checks milestone |
| Click compass tile | Reveals, no feedback message |
| Click already-revealed tile | No effect, no turn cost |
| Click after game over | No effect |
| Losing condition | Turns reach 0 → `.lost`, game over sound, loss recorded |
| Milestone triggered | Mock returns value, `celebrateMilestone` is set |
| Reset game | Board regenerated, turns reset, status `.playing` |
| Apply settings | Closes settings, resets game |

### StatsManagerTests.swift

All tests use an isolated `UserDefaults(suiteName:)` instance, removed in teardown.

| Test | Description |
|------|-------------|
| Record win | Increments `lifetimeWins`, updates streak |
| Record loss | Increments `lifetimeLosses`, resets current streak |
| Best streak tracking | Tracks maximum across win/loss sequences |
| History trimming | Keeps only last 100 games |
| Milestone — first reach | Returns milestone number |
| Milestone — already reached | Returns `nil` |
| Milestone progression | Higher milestone returns new value |
| `getLifetimeStats()` | Correct totals and win rate |
| `getLast10Stats()` | Windowed calculation |
| `getLast100Stats()` | Windowed calculation |
| `clearStats()` | Resets everything |
| Persistence round-trip | New manager with same defaults sees prior data |
| Empty state | Fresh manager returns zero stats |
