# SwiftUI Modernization Audit — Hide & Seek iOS

**Date:** 2026-03-21
**Status:** Draft

## Overview

Full modernization of the Hide & Seek iOS app's SwiftUI layer. Raise deployment target to iOS 26, migrate from `ObservableObject` to `@Observable`, extract monolithic ContentView into individual files, fix all deprecated APIs, add accessibility support, and modernize concurrency/haptics.

## Decisions

- **Deployment target:** iOS 26, Swift 6.2
- **Data flow:** Full migration from `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject` to `@Observable`/`@State`/`@Bindable`
- **File structure:** Extract all types from ContentView.swift into individual files
- **Deprecated APIs:** Fix all (~25 instances across foregroundColor, cornerRadius, NavigationView, etc.)
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

```swift
class GameViewModel: ObservableObject {
    @Published var settings = GameSettings()
    @Published var board: [[Tile]] = []
    @Published var turns: Int = 15
    @Published var gameStatus: GameStatus = .playing
    @Published var friendPos: Position?
    @Published var feedback: FeedbackMessage?
    @Published var showSettings = false
    @Published var showStats = false
    @Published var celebrateMilestone: Int? = nil

    init() { ... }
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

    // Haptic trigger properties — views attach sensoryFeedback() to these
    var lastRevealedContent: ContentType?
    var isGameOver = false

    init(soundManager: SoundPlaying = SoundManager.shared,
         statsTracker: StatsTracking = StatsManager.shared) { ... }
}
```

### Key Changes

- Remove `ObservableObject` conformance and all `@Published` wrappers
- Add `@Observable` and `@MainActor` annotations
- Add `lastRevealedContent` and `isGameOver` properties for driving `sensoryFeedback()` from views
- Update `handleTileClick` to set `lastRevealedContent` after each reveal
- Replace `DispatchQueue.main.asyncAfter` feedback dismissal with `Task { try? await Task.sleep(for: .seconds(2)); feedback = nil }`
- `import Combine` is not needed (no `ObservableObject`)

### View-Side Changes

| Pattern | Before | After |
|---------|--------|-------|
| Owner | `@StateObject private var viewModel = GameViewModel()` | `@State private var viewModel = GameViewModel()` |
| Reader | `@ObservedObject var viewModel: GameViewModel` | `var viewModel: GameViewModel` |
| Binding needed | `@ObservedObject var viewModel: GameViewModel` | `@Bindable var viewModel: GameViewModel` |

`@Bindable` is needed in `SettingsSheetView` (for `$viewModel.showSettings`, `$viewModel.settings.*` bindings).

### Test Impact

Existing `GameViewModelTests` use `@MainActor struct` already. The `MockSoundManager` and `MockStatsTracker` continue to work unchanged. Tests may need minor adjustments for the new `lastRevealedContent`/`isGameOver` properties.

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

Existing separate files (`StatsView.swift`, `MilestoneView.swift`) are modernized in place.

## Section 4: Deprecated API Fixes

Applied during file extraction. Complete list:

| Deprecated | Modern | Occurrences |
|---|---|---|
| `foregroundColor(.x)` | `foregroundStyle(.x)` | ~18 across all views |
| `.cornerRadius(n)` | `.clipShape(.rect(cornerRadius: n))` | ~11 across all views |
| `NavigationView { }` | `NavigationStack { }` | 2: StatsView, SettingsSheetView |
| `.navigationBarTrailing` | `.topBarTrailing` | 2: StatsView, SettingsSheetView |
| `Text("A") + Text("B")` | `Text("\(a)\(b)")` interpolation | 1: HUDView turns display |
| `Binding(get:set:)` | Direct `@Bindable` bindings with `onChange` | 6: SettingsSheetView sliders/toggles |

### SettingsSheetView Binding Migration

The 6 `Binding(get:set:)` instances in SettingsSheetView exist because `GameSettings` is a struct inside `GameViewModel`. With `@Observable` + `@Bindable`, these become direct bindings:

```swift
// Before
Slider(value: Binding(
    get: { Double(viewModel.settings.startingTurns) },
    set: { viewModel.settings.startingTurns = Int($0) }
), in: 5...30, step: 1)

// After — bind to a Double @State and sync via onChange
// Or keep the Binding(get:set:) for Int↔Double conversion only
// (Binding(get:set:) is acceptable for type conversion, just not for side effects)
```

Note: `Binding(get:set:)` for Int↔Double type conversion in Sliders is acceptable — the swiftui-pro rule targets bindings used for side effects. These conversions can stay.

## Section 5: Accessibility

### Dynamic Type

Replace all hardcoded `.font(.system(size:))` with semantic fonts:

| Current | Replacement | Usage |
|---------|-------------|-------|
| `.system(size: 32, weight: .bold)` | `.largeTitle.bold()` | App title |
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

```swift
// On TileButton or GridView:
.sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.lastRevealedContent) { old, new in
    new == .empty || new == .compass
}
.sensoryFeedback(.impact(flexibility: .solid), trigger: viewModel.lastRevealedContent) { old, new in
    new == .coin
}
.sensoryFeedback(.success, trigger: viewModel.lastRevealedContent) { old, new in
    new == .friend
}
.sensoryFeedback(.error, trigger: viewModel.lastRevealedContent) { old, new in
    new == .trap
}
.sensoryFeedback(.error, trigger: viewModel.isGameOver)
```

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
