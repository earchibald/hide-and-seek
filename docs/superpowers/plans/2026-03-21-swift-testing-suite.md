# Swift Testing Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive Swift Testing test coverage to the Hide & Seek iOS game, including protocol-based dependency injection refactoring for testability.

**Architecture:** Protocol-based DI for `SoundManager` and `StatsManager`, injected into `GameViewModel` with production defaults. `StatsManager` accepts a `UserDefaults` instance for isolated persistence testing. All test suites are Swift Testing structs.

**Tech Stack:** Swift Testing, Swift 6.2+, Xcode

**Spec:** `docs/superpowers/specs/2026-03-21-swift-testing-suite-design.md`

---

## File Map

### Production Code (modify)

| File | Change |
|------|--------|
| `HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift` | Add `: SoundPlaying` conformance |
| `HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift` | Add `: StatsTracking` conformance, injectable `UserDefaults`, change `private init` to `private convenience init` |
| `HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift` | Accept `SoundPlaying` and `StatsTracking` via init, use injected dependencies |

### Production Code (create)

| File | Purpose |
|------|---------|
| `HideAndSeekiOS/HideAndSeek/Managers/SoundPlaying.swift` | Protocol for sound/haptic playback |
| `HideAndSeekiOS/HideAndSeek/Managers/StatsTracking.swift` | Protocol for stats recording |

### Test Code (create)

| File | Purpose |
|------|---------|
| `HideAndSeekiOS/HideAndSeekTests/Mocks/MockSoundManager.swift` | Mock for `SoundPlaying` |
| `HideAndSeekiOS/HideAndSeekTests/Mocks/MockStatsTracker.swift` | Mock for `StatsTracking` |
| `HideAndSeekiOS/HideAndSeekTests/TileTests.swift` | Tile model and compass direction tests |
| `HideAndSeekiOS/HideAndSeekTests/GameSettingsTests.swift` | GameSettings default value tests |
| `HideAndSeekiOS/HideAndSeekTests/GameStatsTests.swift` | GameStats/GameResult Codable and StatsData tests |
| `HideAndSeekiOS/HideAndSeekTests/StatsManagerTests.swift` | StatsManager persistence and calculation tests |
| `HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift` | Game logic, board generation, tile click tests |

### Project Configuration (modify)

| File | Change |
|------|--------|
| `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj` | Add `HideAndSeekTests` test target with all test source files |

---

## Task 1: Create Protocols

**Files:**
- Create: `HideAndSeekiOS/HideAndSeek/Managers/SoundPlaying.swift`
- Create: `HideAndSeekiOS/HideAndSeek/Managers/StatsTracking.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create `SoundPlaying.swift`**

```swift
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
```

- [ ] **Step 2: Create `StatsTracking.swift`**

```swift
import Foundation

protocol StatsTracking {
    func recordGame(won: Bool, turnsRemaining: Int)
    func checkMilestone() -> Int?
}
```

- [ ] **Step 3: Add `SoundPlaying` conformance to `SoundManager`**

In `SoundManager.swift`, change:
```swift
class SoundManager {
```
to:
```swift
class SoundManager: SoundPlaying {
```

No other changes needed — existing methods already match the protocol.

- [ ] **Step 4: Add `StatsTracking` conformance to `StatsManager`**

In `StatsManager.swift`, change:
```swift
class StatsManager {
```
to:
```swift
class StatsManager: StatsTracking {
```

No other changes needed — existing methods already match the protocol.

- [ ] **Step 5: Add new protocol files to Xcode project**

Add `PBXFileReference` and `PBXBuildFile` entries for `SoundPlaying.swift` and `StatsTracking.swift` in the pbxproj. Add them to the Managers group (`0A12F38C2F428058007A0625`) and the main target's Sources build phase (`FF0003`).

- [ ] **Step 6: Verify the app builds**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/Managers/SoundPlaying.swift \
       HideAndSeekiOS/HideAndSeek/Managers/StatsTracking.swift \
       HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift \
       HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add SoundPlaying and StatsTracking protocols for DI"
```

---

## Task 2: Refactor StatsManager for Injectable UserDefaults

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift`

- [ ] **Step 1: Add `defaults` property and new initializer**

Replace the current `private init()` and `UserDefaults.standard` usage:

```swift
// Before (lines 10-28):
class StatsManager: StatsTracking {
    static let shared = StatsManager()

    private let userDefaultsKey = "hideAndSeek.playerStats"
    private let maxHistorySize = 100
    private let milestones = [10, 25, 50, 100, 500]

    private var stats: GameStats

    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameStats.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = GameStats()
            saveStats()
        }
    }
```

```swift
// After:
class StatsManager: StatsTracking {
    static let shared = StatsManager()

    private let defaults: UserDefaults
    private let userDefaultsKey = "hideAndSeek.playerStats"
    private let maxHistorySize = 100
    private let milestones = [10, 25, 50, 100, 500]

    private var stats: GameStats

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
```

- [ ] **Step 2: Update `saveStats()` to use `self.defaults`**

```swift
// Before (line 149-153):
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
```

```swift
// After:
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            defaults.set(encoded, forKey: userDefaultsKey)
        }
    }
```

- [ ] **Step 3: Verify the app builds**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift
git commit -m "Refactor StatsManager to accept injectable UserDefaults"
```

---

## Task 3: Refactor GameViewModel for Dependency Injection

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift`

- [ ] **Step 1: Add DI properties and update init**

Add properties and change `init()`:

```swift
// Before (lines 23-44):
class GameViewModel: ObservableObject {
    // Game balance constants
    let TURN_COST_TAP = -1
    let TURN_BONUS_COIN = 1
    let TURN_PENALTY_TRAP = -1
    let TURN_PENALTY_EMPTY = 0
    let GRID_SIZE = 10

    @Published var settings = GameSettings()
    // ... other @Published vars ...

    init() {
        generateBoard()
        turns = settings.startingTurns
    }
```

```swift
// After:
class GameViewModel: ObservableObject {
    // Game balance constants
    let TURN_COST_TAP = -1
    let TURN_BONUS_COIN = 1
    let TURN_PENALTY_TRAP = -1
    let TURN_PENALTY_EMPTY = 0
    let GRID_SIZE = 10

    let soundManager: SoundPlaying
    let statsTracker: StatsTracking

    @Published var settings = GameSettings()
    // ... other @Published vars ...

    init(soundManager: SoundPlaying = SoundManager.shared,
         statsTracker: StatsTracking = StatsManager.shared) {
        self.soundManager = soundManager
        self.statsTracker = statsTracker
        generateBoard()
        turns = settings.startingTurns
    }
```

- [ ] **Step 2: Replace `SoundManager.shared` calls in `handleTileClick`**

```swift
// Before (line 119):
        SoundManager.shared.play(for: tile.content, soundEnabled: settings.soundEnabled, volume: settings.soundVolume)

// After:
        soundManager.play(for: tile.content, soundEnabled: settings.soundEnabled, volume: settings.soundVolume)
```

```swift
// Before (line 159):
            SoundManager.shared.playGameOver(soundEnabled: settings.soundEnabled, volume: settings.soundVolume)

// After:
            soundManager.playGameOver(soundEnabled: settings.soundEnabled, volume: settings.soundVolume)
```

- [ ] **Step 3: Replace `StatsManager.shared` calls in `handleTileClick`**

```swift
// Before (line 132):
            StatsManager.shared.recordGame(won: true, turnsRemaining: turns)

// After:
            statsTracker.recordGame(won: true, turnsRemaining: turns)
```

```swift
// Before (line 133):
            celebrateMilestone = StatsManager.shared.checkMilestone()

// After:
            celebrateMilestone = statsTracker.checkMilestone()
```

```swift
// Before (line 162):
            StatsManager.shared.recordGame(won: false, turnsRemaining: 0)

// After:
            statsTracker.recordGame(won: false, turnsRemaining: 0)
```

- [ ] **Step 4: Verify the app builds**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift
git commit -m "Inject SoundPlaying and StatsTracking into GameViewModel"
```

---

## Task 4: Add Test Target to Xcode Project

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/` directory
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create test directory**

```bash
mkdir -p HideAndSeekiOS/HideAndSeekTests/Mocks
```

- [ ] **Step 2: Create a placeholder test file**

Create `HideAndSeekiOS/HideAndSeekTests/TileTests.swift` with a minimal test to verify the target works:

```swift
import Testing
@testable import HideAndSeek

struct TileTests {
    @Test func tileInitializesUnrevealed() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.isRevealed == false)
    }
}
```

- [ ] **Step 3: Add `HideAndSeekTests` target to `project.pbxproj`**

This requires adding the following sections to the pbxproj:

1. **PBXFileReference** entries for `TileTests.swift` and the test bundle product (`.xctest`)
2. **PBXBuildFile** entry for `TileTests.swift` in the test target's Sources phase
3. **PBXGroup** for `HideAndSeekTests` directory, added to the root group (`EE0001`)
4. **PBXContainerItemProxy** linking test target to app target
5. **PBXTargetDependency** for the test target depending on the app target
6. **PBXNativeTarget** for `HideAndSeekTests` with `com.apple.product-type.bundle.unit-test` product type
7. **PBXSourcesBuildPhase**, **PBXFrameworksBuildPhase**, **PBXResourcesBuildPhase** for the test target
8. **XCBuildConfiguration** entries (Debug/Release) for the test target with:
   - `BUNDLE_LOADER = "$(TEST_HOST)"`
   - `TEST_HOST = "$(BUILT_PRODUCTS_DIR)/HideAndSeek.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HideAndSeek"`
   - `PRODUCT_BUNDLE_IDENTIFIER = com.hideandseek.tests`
   - `SWIFT_VERSION = 5.0`
   - `TARGETED_DEVICE_FAMILY = "1,2"`
   - `GENERATE_INFOPLIST_FILE = YES`
   - `IPHONEOS_DEPLOYMENT_TARGET = 16.0`
9. **XCConfigurationList** for the test target
10. Add the new target to the project's `targets` list in `GG0001`
11. Add the `.xctest` product to the Products group (`EE0003`)

Use unique IDs that don't collide with existing entries (prefix with `TT` for test-related entries).

**Verified pbxproj IDs from the actual project file:**
- Root group: `EE0001`
- Products group: `EE0003`
- Main target: `FF0001` (HideAndSeek)
- Main target Sources build phase: `FF0003`
- Managers group: `0A12F38C2F428058007A0625`
- Project object: `GG0001`
- Project build config list: `GG0002`

- [ ] **Step 4: Verify tests run**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`

If there is no test scheme, create one or use: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -target HideAndSeekTests -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: 1 test passed

- [ ] **Step 5: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/ \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add HideAndSeekTests target with Swift Testing"
```

---

## Task 5: Create Mocks

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/Mocks/MockSoundManager.swift`
- Create: `HideAndSeekiOS/HideAndSeekTests/Mocks/MockStatsTracker.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create `MockSoundManager.swift`**

```swift
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
```

- [ ] **Step 2: Create `MockStatsTracker.swift`**

```swift
import Foundation
@testable import HideAndSeek

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

- [ ] **Step 3: Add mock files to test target in pbxproj**

Add `PBXFileReference`, `PBXBuildFile`, and group entries for both mock files. Add them to the `Mocks` subgroup under `HideAndSeekTests`, and to the test target's Sources build phase.

- [ ] **Step 4: Verify tests still pass**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: 1 test passed (existing `tileInitializesUnrevealed`)

- [ ] **Step 5: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/Mocks/ \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add MockSoundManager and MockStatsTracker test doubles"
```

---

## Task 6: Write TileTests

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeekTests/TileTests.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj` (if not already added)

- [ ] **Step 1: Write complete TileTests**

Replace the placeholder `TileTests.swift` with the full test suite:

```swift
import Testing
@testable import HideAndSeek

struct TileTests {
    @Test func tileInitializesUnrevealed() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.isRevealed == false)
    }

    @Test func contentEmojiFriend() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .friend)
        #expect(tile.contentEmoji(friendPos: nil) == "🕵️‍♀️")
    }

    @Test func contentEmojiCoin() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .coin)
        #expect(tile.contentEmoji(friendPos: nil) == "💰")
    }

    @Test func contentEmojiTrap() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .trap)
        #expect(tile.contentEmoji(friendPos: nil) == "🕸️")
    }

    @Test func contentEmojiEmpty() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.contentEmoji(friendPos: nil) == "❌")
    }

    @Test func contentEmojiCompassReturnsArrow() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        let emoji = tile.contentEmoji(friendPos: Position(row: 0, col: 5))
        // Friend is due north — should be ↑
        #expect(emoji == "↑")
    }

    @Test func compassWithNoFriendPos() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        #expect(tile.contentEmoji(friendPos: nil) == "•")
    }

    // Parameterized test for all 8 compass directions
    struct CompassCase: CustomTestStringConvertible, Sendable {
        let tileRow: Int
        let tileCol: Int
        let friendRow: Int
        let friendCol: Int
        let expectedArrow: String
        let testDescription: String

        var description: String { testDescription }
    }

    static let compassCases: [CompassCase] = [
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 5, friendCol: 9, expectedArrow: "→", testDescription: "East"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 9, expectedArrow: "↘", testDescription: "Southeast"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 5, expectedArrow: "↓", testDescription: "South"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 1, expectedArrow: "↙", testDescription: "Southwest"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 5, friendCol: 1, expectedArrow: "←", testDescription: "West"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 1, expectedArrow: "↖", testDescription: "Northwest"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 5, expectedArrow: "↑", testDescription: "North"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 9, expectedArrow: "↗", testDescription: "Northeast"),
    ]

    @Test(arguments: compassCases)
    func compassDirection(testCase: CompassCase) {
        let tile = Tile(row: testCase.tileRow, col: testCase.tileCol, terrain: .grass, content: .compass)
        let arrow = tile.contentEmoji(friendPos: Position(row: testCase.friendRow, col: testCase.friendCol))
        #expect(arrow == testCase.expectedArrow)
    }

    @Test func compassSamePosition() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        // Same position — angle is 0, so should return "→" (atan2(0,0) = 0)
        let arrow = tile.contentEmoji(friendPos: Position(row: 5, col: 5))
        // atan2(0,0) returns 0 which maps to → in the implementation
        #expect(arrow == "→")
    }
}
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All TileTests pass

- [ ] **Step 3: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/TileTests.swift
git commit -m "Add TileTests with parameterized compass direction coverage"
```

---

## Task 7: Write GameSettingsTests

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/GameSettingsTests.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write GameSettingsTests**

```swift
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
```

- [ ] **Step 2: Add file to test target in pbxproj**

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/GameSettingsTests.swift \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add GameSettingsTests for default values and mutability"
```

---

## Task 8: Write GameStatsTests

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/GameStatsTests.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write GameStatsTests**

```swift
import Testing
import Foundation
@testable import HideAndSeek

struct GameStatsTests {
    @Test func emptyGameStatsRoundTrip() throws {
        let stats = GameStats()
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)

        #expect(decoded.gameHistory.isEmpty)
        #expect(decoded.lifetimeWins == 0)
        #expect(decoded.lifetimeLosses == 0)
        #expect(decoded.currentStreak == 0)
        #expect(decoded.bestStreak == 0)
        #expect(decoded.lastMilestone == nil)
    }

    @Test func populatedGameStatsRoundTrip() throws {
        var stats = GameStats()
        stats.gameHistory = [
            GameResult(won: true, turnsRemaining: 5, date: Date()),
            GameResult(won: false, turnsRemaining: 0, date: Date()),
        ]
        stats.lifetimeWins = 10
        stats.lifetimeLosses = 5
        stats.currentStreak = 3
        stats.bestStreak = 7
        stats.lastMilestone = 10

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)

        #expect(decoded.gameHistory.count == 2)
        #expect(decoded.lifetimeWins == 10)
        #expect(decoded.lifetimeLosses == 5)
        #expect(decoded.currentStreak == 3)
        #expect(decoded.bestStreak == 7)
        #expect(decoded.lastMilestone == 10)
    }

    @Test func gameResultPreservesFields() throws {
        let date = Date()
        let result = GameResult(won: true, turnsRemaining: 7, date: date)

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(GameResult.self, from: data)

        #expect(decoded.won == true)
        #expect(decoded.turnsRemaining == 7)
        // Date precision may differ slightly with JSON encoding, check within 1 second
        #expect(abs(decoded.date.timeIntervalSince(date)) < 1)
    }

    @Test func winRateStringFormatting() {
        let stats = StatsData(
            gamesPlayed: 4,
            wins: 3,
            losses: 1,
            winRate: 75.0,
            currentStreak: 2,
            bestStreak: 3
        )
        #expect(stats.winRateString == "75.0%")
    }

    @Test func winRateStringZero() {
        let stats = StatsData(
            gamesPlayed: 0,
            wins: 0,
            losses: 0,
            winRate: 0,
            currentStreak: 0,
            bestStreak: 0
        )
        #expect(stats.winRateString == "0.0%")
    }
}
```

- [ ] **Step 2: Add file to test target in pbxproj**

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/GameStatsTests.swift \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add GameStatsTests for Codable round-trips and StatsData"
```

---

## Task 9: Write StatsManagerTests

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/StatsManagerTests.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write StatsManagerTests**

Each test creates an isolated `UserDefaults` suite. The struct uses `init`/`deinit` for setup/teardown per Swift Testing conventions.

```swift
import Testing
import Foundation
@testable import HideAndSeek

struct StatsManagerTests {
    private let suiteName: String
    private let defaults: UserDefaults
    private let manager: StatsManager

    init() {
        suiteName = "test.statsManager.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        manager = StatsManager(defaults: defaults)
    }

    // Clean up the UserDefaults suite after each test
    // Note: Swift Testing structs do not support deinit, so we rely on
    // unique suite names per test to avoid collision. If cleanup is needed,
    // call removePersistentDomain at the end of each test or use a helper.

    private func cleanup() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test func emptyStateReturnsZeroStats() {
        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 0)
        #expect(stats.wins == 0)
        #expect(stats.losses == 0)
        #expect(stats.winRate == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.bestStreak == 0)
        cleanup()
    }

    @Test func recordWinIncrementsWinsAndStreak() {
        manager.recordGame(won: true, turnsRemaining: 5)
        let stats = manager.getLifetimeStats()
        #expect(stats.wins == 1)
        #expect(stats.losses == 0)
        #expect(stats.currentStreak == 1)
        cleanup()
    }

    @Test func recordLossIncrementsLossesAndResetsStreak() {
        manager.recordGame(won: true, turnsRemaining: 5)
        manager.recordGame(won: true, turnsRemaining: 3)
        manager.recordGame(won: false, turnsRemaining: 0)
        let stats = manager.getLifetimeStats()
        #expect(stats.wins == 2)
        #expect(stats.losses == 1)
        #expect(stats.currentStreak == 0)
        cleanup()
    }

    @Test func bestStreakTracksMaximum() {
        // Win 3 in a row
        for _ in 0..<3 { manager.recordGame(won: true, turnsRemaining: 5) }
        // Lose one
        manager.recordGame(won: false, turnsRemaining: 0)
        // Win 2 in a row
        for _ in 0..<2 { manager.recordGame(won: true, turnsRemaining: 5) }

        let stats = manager.getLifetimeStats()
        #expect(stats.bestStreak == 3)
        #expect(stats.currentStreak == 2)
        cleanup()
    }

    @Test func historyTrimmingKeepsLast100() {
        for i in 0..<105 {
            manager.recordGame(won: i % 2 == 0, turnsRemaining: i % 2 == 0 ? 5 : 0)
        }
        let stats = manager.getLast100Stats()
        #expect(stats.gamesPlayed == 100)
        cleanup()
    }

    @Test func milestoneFirstReach() {
        // Reach 10 wins
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        let milestone = manager.checkMilestone()
        #expect(milestone == 10)
        cleanup()
    }

    @Test func milestoneAlreadyReachedReturnsNil() {
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        _ = manager.checkMilestone() // Consume the milestone
        let milestone = manager.checkMilestone()
        #expect(milestone == nil)
        cleanup()
    }

    @Test func milestoneProgression() {
        // Reach 10 wins
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }
        let first = manager.checkMilestone()
        #expect(first == 10)

        // Reach 25 wins (15 more)
        for _ in 0..<15 { manager.recordGame(won: true, turnsRemaining: 5) }
        let second = manager.checkMilestone()
        #expect(second == 25)
        cleanup()
    }

    @Test func getLifetimeStatsCalculatesWinRate() {
        for _ in 0..<3 { manager.recordGame(won: true, turnsRemaining: 5) }
        manager.recordGame(won: false, turnsRemaining: 0)

        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 4)
        #expect(stats.wins == 3)
        #expect(stats.losses == 1)
        #expect(stats.winRate == 75.0)
        cleanup()
    }

    @Test func getLast10StatsWindowedCalculation() {
        // Play 15 games: first 5 losses, then 10 wins
        for _ in 0..<5 { manager.recordGame(won: false, turnsRemaining: 0) }
        for _ in 0..<10 { manager.recordGame(won: true, turnsRemaining: 5) }

        let last10 = manager.getLast10Stats()
        #expect(last10.gamesPlayed == 10)
        #expect(last10.wins == 10)
        #expect(last10.losses == 0)
        cleanup()
    }

    @Test func getLast100StatsWindowedCalculation() {
        for _ in 0..<50 { manager.recordGame(won: true, turnsRemaining: 5) }
        for _ in 0..<50 { manager.recordGame(won: false, turnsRemaining: 0) }

        let last100 = manager.getLast100Stats()
        #expect(last100.gamesPlayed == 100)
        #expect(last100.wins == 50)
        #expect(last100.losses == 50)
        cleanup()
    }

    @Test func clearStatsResetsEverything() {
        for _ in 0..<5 { manager.recordGame(won: true, turnsRemaining: 5) }
        manager.clearStats()

        let stats = manager.getLifetimeStats()
        #expect(stats.gamesPlayed == 0)
        #expect(stats.wins == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.bestStreak == 0)
        cleanup()
    }

    @Test func persistenceRoundTrip() {
        manager.recordGame(won: true, turnsRemaining: 5)
        manager.recordGame(won: true, turnsRemaining: 3)

        // Create a new manager with the same defaults — should load persisted data
        let manager2 = StatsManager(defaults: defaults)
        let stats = manager2.getLifetimeStats()
        #expect(stats.wins == 2)
        #expect(stats.currentStreak == 2)
        cleanup()
    }
}
```

- [ ] **Step 2: Add file to test target in pbxproj**

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All StatsManagerTests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/StatsManagerTests.swift \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add StatsManagerTests with isolated UserDefaults persistence"
```

---

## Task 10: Write GameViewModelTests

**Files:**
- Create: `HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift`
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write GameViewModelTests**

This is the largest test file. Tests create a `GameViewModel` with mock dependencies. Board-scanning helpers extract tile positions by content type.

```swift
import Testing
import SwiftUI
@testable import HideAndSeek

@MainActor
struct GameViewModelTests {
    private let mockSound: MockSoundManager
    private let mockStats: MockStatsTracker
    private let vm: GameViewModel

    init() {
        mockSound = MockSoundManager()
        mockStats = MockStatsTracker()
        vm = GameViewModel(soundManager: mockSound, statsTracker: mockStats)
    }

    // MARK: - Helpers

    /// Find the first position on the board with the given content type
    private func findTile(_ content: ContentType) -> Position? {
        for row in 0..<vm.GRID_SIZE {
            for col in 0..<vm.GRID_SIZE {
                if vm.board[row][col].content == content {
                    return Position(row: row, col: col)
                }
            }
        }
        return nil
    }

    /// Count tiles with the given content type
    private func countTiles(_ content: ContentType) -> Int {
        var count = 0
        for row in vm.board {
            for tile in row {
                if tile.content == content { count += 1 }
            }
        }
        return count
    }

    // MARK: - Game Balance Constants

    @Test func gameBalanceConstants() {
        #expect(vm.TURN_COST_TAP == -1)
        #expect(vm.TURN_BONUS_COIN == 1)
        #expect(vm.TURN_PENALTY_TRAP == -1)
        #expect(vm.TURN_PENALTY_EMPTY == 0)
        #expect(vm.GRID_SIZE == 10)
    }

    // MARK: - Board Generation

    @Test func boardIs10x10() {
        #expect(vm.board.count == 10)
        for row in vm.board {
            #expect(row.count == 10)
        }
    }

    @Test func boardHasExactlyOneFriend() {
        #expect(countTiles(.friend) == 1)
    }

    @Test func boardHasCorrectCoinCount() {
        #expect(countTiles(.coin) == vm.settings.coinCount)
    }

    @Test func boardHasCorrectTrapCount() {
        #expect(countTiles(.trap) == vm.settings.trapCount)
    }

    @Test func boardHasCorrectCompassCount() {
        #expect(countTiles(.compass) == vm.settings.compassCount)
    }

    @Test func remainingTilesAreEmpty() {
        let totalTiles = vm.GRID_SIZE * vm.GRID_SIZE
        let placedCount = 1 + vm.settings.coinCount + vm.settings.trapCount + vm.settings.compassCount
        #expect(countTiles(.empty) == totalTiles - placedCount)
    }

    // MARK: - Tile Click Behavior

    @Test func clickEmptyTile() throws {
        let pos = try #require(findTile(.empty))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 1)
        #expect(vm.feedback != nil)
        #expect(vm.feedback?.color == .gray)
    }

    @Test func clickCoinTile() throws {
        let pos = try #require(findTile(.coin))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore) // net 0: -1 tap + 1 bonus
        #expect(vm.feedback?.color == .yellow)
    }

    @Test func clickTrapTile() throws {
        let pos = try #require(findTile(.trap))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 2) // net -2: -1 tap + -1 penalty
        #expect(vm.feedback?.color == .red)
    }

    @Test func clickFriendTileWinsGame() throws {
        let pos = try #require(findTile(.friend))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.gameStatus == .won)
        #expect(vm.turns == turnsBefore - 1)
        #expect(vm.feedback?.color == .green)
        // Verify stats tracker was called
        #expect(mockStats.recordedGames.count == 1)
        #expect(mockStats.recordedGames[0].won == true)
    }

    @Test func clickCompassTile() throws {
        let pos = try #require(findTile(.compass))
        let turnsBefore = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.board[pos.row][pos.col].isRevealed == true)
        #expect(vm.turns == turnsBefore - 1)
        // Compass produces no feedback message
        #expect(vm.feedback == nil)
    }

    @Test func clickAlreadyRevealedTileHasNoEffect() throws {
        let pos = try #require(findTile(.empty))
        vm.handleTileClick(row: pos.row, col: pos.col)
        let turnsAfterFirst = vm.turns

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(vm.turns == turnsAfterFirst) // No additional cost
    }

    @Test func clickAfterGameOverHasNoEffect() throws {
        // Win the game first
        let friendPos = try #require(findTile(.friend))
        vm.handleTileClick(row: friendPos.row, col: friendPos.col)
        #expect(vm.gameStatus == .won)

        let turnsAfterWin = vm.turns
        // Try clicking another tile
        let emptyPos = try #require(findTile(.empty))
        vm.handleTileClick(row: emptyPos.row, col: emptyPos.col)
        #expect(vm.turns == turnsAfterWin)
        #expect(vm.board[emptyPos.row][emptyPos.col].isRevealed == false)
    }

    @Test func losingConditionWhenTurnsReachZero() throws {
        // Set turns to 2 so a trap click (-2) triggers loss
        vm.turns = 2
        let trapPos = try #require(findTile(.trap))
        vm.handleTileClick(row: trapPos.row, col: trapPos.col)
        #expect(vm.gameStatus == .lost)
        #expect(mockSound.gameOverCallCount == 1)
        #expect(mockStats.recordedGames.count == 1)
        #expect(mockStats.recordedGames[0].won == false)
    }

    @Test func milestoneTriggered() throws {
        mockStats.milestoneToReturn = 10
        let friendPos = try #require(findTile(.friend))

        vm.handleTileClick(row: friendPos.row, col: friendPos.col)

        #expect(vm.celebrateMilestone == 10)
    }

    @Test func soundVolumePassthrough() throws {
        vm.settings.soundVolume = 0.5
        vm.settings.soundEnabled = true
        let pos = try #require(findTile(.empty))

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(mockSound.lastSoundEnabled == true)
        #expect(mockSound.lastVolume == 0.5)
    }

    @Test func soundDisabledPassthrough() throws {
        vm.settings.soundEnabled = false
        let pos = try #require(findTile(.empty))

        vm.handleTileClick(row: pos.row, col: pos.col)

        #expect(mockSound.lastSoundEnabled == false)
    }

    // MARK: - Reset and Settings

    @Test func resetGameRestoresInitialState() throws {
        // Click some tiles first
        let pos = try #require(findTile(.empty))
        vm.handleTileClick(row: pos.row, col: pos.col)

        vm.resetGame()

        #expect(vm.gameStatus == .playing)
        #expect(vm.turns == vm.settings.startingTurns)
        #expect(vm.feedback == nil)
        // Board should be freshly generated (all tiles unrevealed)
        for row in vm.board {
            for tile in row {
                #expect(tile.isRevealed == false)
            }
        }
    }

    @Test func applySettingsClosesSettingsAndResets() {
        vm.showSettings = true
        vm.applySettings()

        #expect(vm.showSettings == false)
        #expect(vm.gameStatus == .playing)
        #expect(vm.turns == vm.settings.startingTurns)
    }
}
```

- [ ] **Step 2: Add file to test target in pbxproj**

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All GameViewModelTests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Add GameViewModelTests with full game logic coverage"
```

---

## Task 11: Final Verification

- [ ] **Step 1: Run the complete test suite**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All tests pass (TileTests, GameSettingsTests, GameStatsTests, StatsManagerTests, GameViewModelTests)

- [ ] **Step 2: Verify the app still builds and runs**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Review test count**

Verify approximate test count:
- TileTests: ~13 tests (5 emoji + 8 parameterized compass + same-position + no-friendPos)
- GameSettingsTests: 2 tests
- GameStatsTests: 5 tests
- StatsManagerTests: 12 tests
- GameViewModelTests: ~17 tests

Total: ~49 tests
