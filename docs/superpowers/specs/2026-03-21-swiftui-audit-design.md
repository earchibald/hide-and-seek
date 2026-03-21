# SwiftUI Modernization Audit — Hide & Seek iOS

**Date:** 2026-03-21
**Status:** Draft

## Overview

Full modernization of the Hide & Seek iOS app's SwiftUI layer. Raise deployment target to iOS 26, migrate from `ObservableObject` to `@Observable`, extract monolithic ContentView into individual files, fix all deprecated APIs, add accessibility support, and modernize concurrency/haptics.

## Decisions

- **Deployment target:** iOS 26, Swift 6.2
- **Data flow:** Full migration from `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject` to `@Observable`/`@State`/`@Bindable`
- **File structure:** Extract all types from ContentView.swift into individual files
- **Deprecated APIs:** Fix all (~50 instances across foregroundColor, cornerRadius, NavigationView, etc.)
- **Accessibility:** Full pass — Dynamic Type, VoiceOver labels, Reduce Motion
- **Haptics:** Migrate from UIKit haptic APIs to SwiftUI `sensoryFeedback()` modifiers
- **Concurrency:** Replace all `DispatchQueue` usage with Swift concurrency
- **Approach:** Architecture first — deployment target → @Observable → file extraction → deprecated APIs → accessibility → haptics/concurrency

## Section 1: Deployment Target & Project Config

Update `project.pbxproj`:
- `IPHONEOS_DEPLOYMENT_TARGET`: `16.0` → `26.0` (4 XCBuildConfiguration entries: project Debug/Release, app target Debug/Release)
- `SWIFT_VERSION`: `5.0` → `6.2` (2 app target entries: Debug/Release)

## Section 2: GameViewModel Migration to @Observable

### Before

The ViewModel already has DI properties (`soundManager`, `statsTracker`) from the testing refactor. The migration removes `ObservableObject`/`@Published` and adds `@Observable`/`@MainActor`:

```swift
class GameViewModel: ObservableObject {
    let soundManager: SoundPlaying
    let statsTracker: StatsTracking

    @Published var settings = GameSettings()
    @Published var board: [[Tile]] = []
    @Published var turns: Int = 15
    @Published var gameStatus: GameStatus = .playing
    @Published var friendPos: Position?
    @Published var feedback: FeedbackMessage?
    @Published var showSettings = false
    @Published var showStats = false
    @Published var celebrateMilestone: Int? = nil

    init(soundManager: SoundPlaying = SoundManager.shared,
         statsTracker: StatsTracking = StatsManager.shared) { ... }
}
```

### After

```swift
@Observable @MainActor
class GameViewModel {
    let soundManager: SoundPlaying
    let statsTracker: StatsTracking

    var settings = GameSettings()
    var board: [[Tile]] = []
    var turns: Int = 15
    var gameStatus: GameStatus = .playing
    var friendPos: Position?
    var feedback: FeedbackMessage?
    var showSettings = false
    var showStats = false
    var celebrateMilestone: Int? = nil

    // Haptic trigger — a counter that increments on each reveal, paired with content type.
    // Using a counter ensures sensoryFeedback fires even for consecutive same-content tiles.
    var revealCount = 0
    var lastRevealedContent: ContentType?
    var isGameOver = false

    init(soundManager: SoundPlaying = SoundManager.shared,
         statsTracker: StatsTracking = StatsManager.shared) { ... }
}
```

### Key Changes

- Remove `ObservableObject` conformance and all `@Published` wrappers
- Add `@Observable` and `@MainActor` annotations
- Add `revealCount`, `lastRevealedContent`, and `isGameOver` properties for driving `sensoryFeedback()` from views
- Update `handleTileClick` to increment `revealCount` and set `lastRevealedContent` after each reveal (counter ensures haptics fire even for consecutive same-content tiles)
- Replace `DispatchQueue.main.asyncAfter` feedback dismissal with `Task { try? await Task.sleep(for: .seconds(2)); feedback = nil }`

### View-Side Changes

| Pattern | Before | After |
|---------|--------|-------|
| Owner | `@StateObject private var viewModel = GameViewModel()` | `@State private var viewModel = GameViewModel()` |
| Reader | `@ObservedObject var viewModel: GameViewModel` | `var viewModel: GameViewModel` |
| Binding needed | `@ObservedObject var viewModel: GameViewModel` | `@Bindable var viewModel: GameViewModel` |

`@Bindable` is needed in `SettingsSheetView` (for `$viewModel.showSettings`, `$viewModel.settings.*` bindings).

### Test Impact

Existing `GameViewModelTests` use `@MainActor struct` already, so test instantiation (`let vm = GameViewModel(soundManager: mock, statsTracker: mock)`) continues to work under `@MainActor` isolation. The `MockSoundManager` and `MockStatsTracker` continue to work unchanged. Tests may need minor adjustments for the new `revealCount`/`lastRevealedContent`/`isGameOver` properties.

Total `@ObservedObject` instances to migrate: 10 (8 in ContentView.swift, 1 in StatsView.swift, 1 in MilestoneView.swift).

## Section 3: File Extraction

Extract ContentView.swift (343 lines, 9 types) into individual files, applying modern APIs during extraction:

| New file | Type | Notes |
|----------|------|-------|
| `Views/ContentView.swift` | `ContentView` | Trimmed to ~30 lines, owns `@State var viewModel` |
| `Views/HUDView.swift` | `HUDView` | Fix Text `+` concatenation |
| `Views/GridView.swift` | `GridView` | |
| `Views/TileButton.swift` | `TileButton` | Add accessibility labels |
| `Views/WinView.swift` | `WinView` | |
| `Views/LoseView.swift` | `LoseView` | |
| `Views/StatsButtonView.swift` | `StatsButtonView` | |
| `Views/SettingsToggleView.swift` | `SettingsToggleView` | Renamed from `SettingsView` to avoid SwiftUI conflict |
| `Views/SettingsSheetView.swift` | `SettingsSheetView` | Uses `@Bindable`, `NavigationStack` |

All extracted files use modern patterns from the start:
- `var viewModel: GameViewModel` (not `@ObservedObject`)
- `foregroundStyle()` (not `foregroundColor()`)
- `.clipShape(.rect(cornerRadius:))` (not `.cornerRadius()`)

Existing separate files (`StatsView.swift`, `MilestoneView.swift`) are modernized in place. `StatsSectionView` stays co-located in `StatsView.swift` since it's a private helper used only by `StatsView`.

`HideAndSeekApp.swift` keeps the `_ = SoundManager.shared` preload — still needed for audio even after haptics are removed from SoundManager.

## Section 4: Deprecated API Fixes

Applied during file extraction. Complete list:

| Deprecated | Modern | Occurrences |
|---|---|---|
| `foregroundColor(.x)` | `foregroundStyle(.x)` | 31 (12 ContentView, 15 StatsView, 4 MilestoneView) |
| `.cornerRadius(n)` | `.clipShape(.rect(cornerRadius: n))` | 15 (10 ContentView, 2 StatsView, 3 MilestoneView) |
| `NavigationView { }` | `NavigationStack { }` | 2: StatsView, SettingsSheetView |
| `.navigationBarTrailing` | `.topBarTrailing` | 2: StatsView, SettingsSheetView |
| `Text("A") + Text("B")` | `Text("\(a)\(b)")` interpolation | 1: HUDView turns display |
| `Binding(get:set:)` for Toggle | Direct `$viewModel.settings.soundEnabled` | 1: SettingsSheetView Toggle |
| `Binding(get:set:)` for Sliders | Keep as-is (Int↔Double conversion) | 5: SettingsSheetView Sliders |

### SettingsSheetView Binding Migration

Of the 6 `Binding(get:set:)` instances in SettingsSheetView:

- **1 Toggle** (`soundEnabled`): This is a direct Bool↔Bool passthrough and should be replaced with `$viewModel.settings.soundEnabled` via `@Bindable`.
- **5 Sliders** (startingTurns, trapCount, coinCount, compassCount, soundVolume): These perform Int↔Double or Float↔Double conversion. `Binding(get:set:)` for pure type conversion is acceptable per swiftui-pro rules — these stay as-is.

## Section 5: Accessibility

### Dynamic Type

Replace all 26 hardcoded `.font(.system(size:))` instances with semantic fonts:

| Current | Replacement | Usage |
|---------|-------------|-------|
| `.system(size: 80)` | `.system(size: 80)` | Trophy emoji (keep — decorative, not text) |
| `.system(size: 36, weight: .heavy)` | `.largeTitle.weight(.heavy)` | Milestone win count |
| `.system(size: 32, weight: .bold)` | `.largeTitle.bold()` | App title |
| `.system(size: 28, weight: .bold)` | `.title.bold()` | Milestone heading |
| `.system(size: 24, weight: .bold)` | `.title2.bold()` | Win/loss headings, tile emoji |
| `.system(size: 20, weight: .bold)` | `.title3.bold()` | HUD turns |
| `.system(size: 18, weight: .bold)` | `.headline` | Buttons, feedback |
| `.system(size: 16, weight: .bold)` | `.subheadline.bold()` | Stats button, settings |
| `.system(size: 16)` / `.system(size: 15)` | `.subheadline` | Win/loss messages, stats rows |
| `.system(size: 14)` | `.caption` | Subtitle, section headers |
| `.system(size: 11)` | `.caption2` | Instructions |

### VoiceOver

- **TileButton:** Add `accessibilityLabel` describing the tile state: terrain type when hidden, content type when revealed. Add `accessibilityHint("Tap to reveal this tile")` when playable.
- **Grid:** Add `accessibilityLabel("Game board")` to the grid container.
- **HUD:** Ensure turns count is read correctly.
- **Win/Loss views:** Labels are already text-based, should work.
- **Stats sections:** Labels are text-based, should work.

### Reduce Motion

In `MilestoneView`, check `@Environment(\.accessibilityReduceMotion)`:
- If true: skip the scale animation, use opacity fade only
- If false: keep existing spring animation

## Section 6: Haptics Modernization

### Current Architecture

`SoundManager` handles both audio and haptics. `GameViewModel.handleTileClick()` calls `soundManager.play(for:soundEnabled:volume:)` which plays a sound AND triggers a UIKit haptic.

### New Architecture

Split concerns:
- **`SoundManager`** keeps audio playback only. Remove all `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` code and the `UIKit` import.
- **Haptics** move to the view layer via `.sensoryFeedback()` modifiers on `TileButton` and `ContentView`, triggered by `viewModel.lastRevealedContent` and `viewModel.isGameOver` changes.

The trigger uses `revealCount` (an incrementing Int) so haptics fire even for consecutive same-content tiles:

```swift
// On GridView or ContentView:
.sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.revealCount) { _, _ in
    viewModel.lastRevealedContent == .empty || viewModel.lastRevealedContent == .compass
}
.sensoryFeedback(.impact(flexibility: .solid), trigger: viewModel.revealCount) { _, _ in
    viewModel.lastRevealedContent == .coin
}
.sensoryFeedback(.success, trigger: viewModel.revealCount) { _, _ in
    viewModel.lastRevealedContent == .friend
}
.sensoryFeedback(.error, trigger: viewModel.revealCount) { _, _ in
    viewModel.lastRevealedContent == .trap
}
.sensoryFeedback(.error, trigger: viewModel.isGameOver)
```

Note: The game-over haptic is intentionally simplified to a single `.error` feedback. The original 5-pulse UIKit haptic loop over 1 second cannot be replicated with `sensoryFeedback()`. This is an acceptable trade-off for full SwiftUI-native haptics.

### Concurrency

Replace `DispatchQueue.main.asyncAfter` in `GameViewModel.handleTileClick()`:

```swift
// Before
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    self.feedback = nil
}

// After
Task { @MainActor in
    try? await Task.sleep(for: .seconds(2))
    feedback = nil
}
```

Replace `DispatchQueue.main.asyncAfter` loop in `SoundManager.playGameOver()`:

```swift
// Before
for i in 0..<5 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { ... }
}

// After — haptics handled by view-layer sensoryFeedback(), so this loop is removed entirely
```

## Section 7: StatsView Singleton Access

`StatsView` currently calls `StatsManager.shared` directly (lines 22, 28, 34, 68). This bypasses the DI pattern.

**Fix:** Add a `StatsProviding` protocol (or expand `StatsTracking`) with the read methods, inject into views that need stats. Or simpler: have `GameViewModel` expose computed stats properties that delegate to its `statsTracker`. Since `StatsView` is presented as a sheet from `ContentView` which owns the ViewModel, it can access stats through the ViewModel.

Simplest approach: `StatsView` receives `StatsManager` directly via init parameter instead of using `.shared`. The `StatsTracking` protocol doesn't need to change since these are read-only methods not called by `GameViewModel`.
