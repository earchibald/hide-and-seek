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

// Provide default volume parameter to match existing call sites
extension SoundPlaying {
    func play(for contentType: ContentType, soundEnabled: Bool) {
        play(for: contentType, soundEnabled: soundEnabled, volume: 1.0)
    }
    func playGameOver(soundEnabled: Bool) {
        playGameOver(soundEnabled: soundEnabled, volume: 1.0)
    }
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

- `SoundManager: SoundPlaying` — existing methods match the protocol requirements. The protocol extension provides default `volume` parameters to preserve existing call sites that don't pass `volume`.
- `StatsManager: StatsTracking` — methods already match, just add conformance. Note: `StatsTracking` only includes the two methods `GameViewModel` calls. Tests for `getLifetimeStats()`, `getLast10Stats()`, `getLast100Stats()`, and `clearStats()` operate directly on the concrete `StatsManager` class.

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

All internal `UserDefaults.standard` references change to `self.defaults`. Specifically: `saveStats()` (line 151) and `init()` (lines 21-22) — exactly 2 references to update.

### Implementation Notes

- **`@MainActor` isolation:** `GameViewModel` is an `ObservableObject` with `@Published` properties. Tests that access these properties may need `@MainActor` annotation or should run on the main actor.
- **Feedback timing:** `handleTileClick` schedules `feedback = nil` after a 2-second `DispatchQueue.main.asyncAfter` delay. Tests should verify feedback state immediately after the click, before the delay fires.
- **Board randomness:** Board generation uses `Int.random` and `Array.shuffle`. Tests verify invariants (correct content counts, grid dimensions) by scanning the generated board, not by controlling the random seed.
- **UserDefaults teardown:** Each `StatsManagerTests` test creates an isolated `UserDefaults(suiteName:)`. Clean up with `UserDefaults.removePersistentDomain(forName:)` in `deinit`.

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
| Click trap tile | Reveals, net -2 turns (tap cost + trap penalty), red feedback |
| Click friend tile | Sets `.won`, costs 1 turn, records win via stats tracker, checks milestone |
| Click compass tile | Reveals, costs 1 turn, no feedback message |
| Click already-revealed tile | No effect, no turn cost |
| Click after game over | No effect |
| Losing condition | Turns reach 0 → `.lost`, game over sound, loss recorded |
| Milestone triggered | Mock returns value, `celebrateMilestone` is set |
| Reset game | Board regenerated, turns reset, status `.playing` |
| Apply settings | Closes settings, resets game |
| Sound/volume passthrough | Verify correct `soundEnabled` and `volume` values reach mock |
| Game balance constants | `TURN_COST_TAP`, `TURN_BONUS_COIN`, `TURN_PENALTY_TRAP`, `TURN_PENALTY_EMPTY`, `GRID_SIZE` have expected values |

### StatsManagerTests.swift

All tests use an isolated `UserDefaults(suiteName:)` instance, removed in teardown.

| Test | Description |
|------|-------------|
| Record win | Increments `lifetimeWins`, updates streak |
| Record loss | Increments `lifetimeLosses`, resets current streak |
| Best streak tracking | Tracks maximum across win/loss sequences |
| History trimming | Record 101+ games, verify only last 100 retained (checked via `getLast100Stats()` count) |
| Milestone — first reach | Returns milestone number (test with known milestones: 10, 25, 50, 100, 500) |
| Milestone — already reached | Returns `nil` on subsequent calls |
| Milestone progression | Reaching higher milestone (e.g., 25 after 10) returns the new value |
| `getLifetimeStats()` | Correct totals and win rate |
| `getLast10Stats()` | Windowed calculation |
| `getLast100Stats()` | Windowed calculation |
| `clearStats()` | Resets everything |
| Persistence round-trip | New manager with same defaults sees prior data |
| Empty state | Fresh manager returns zero stats |
