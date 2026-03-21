# SwiftUI Modernization Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the Hide & Seek iOS app's SwiftUI layer — iOS 26 deployment, `@Observable` migration, file extraction, deprecated API fixes, accessibility, and haptics/concurrency modernization.

**Architecture:** Architecture-first approach: deployment target → `@Observable` → file extraction (with modern APIs applied during extraction) → accessibility → haptics/concurrency.

**Tech Stack:** SwiftUI, Swift 6.2, iOS 26, Swift Testing

**Spec:** `docs/superpowers/specs/2026-03-21-swiftui-audit-design.md`

---

## File Map

### Production Code (modify)

| File | Change |
|------|--------|
| `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj` | Deployment target → 26.0, Swift → 6.2, add new view files |
| `HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift` | `@Observable @MainActor`, remove `@Published`, add haptic trigger properties, Swift concurrency |
| `HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift` | Remove UIKit haptics, keep audio only |
| `HideAndSeekiOS/HideAndSeek/Views/ContentView.swift` | Trim to owner view only, `@State`, attach `sensoryFeedback()` |
| `HideAndSeekiOS/HideAndSeek/Views/StatsView.swift` | `NavigationStack`, `foregroundStyle`, Dynamic Type, remove singleton access |
| `HideAndSeekiOS/HideAndSeek/Views/MilestoneView.swift` | `foregroundStyle`, `clipShape`, Dynamic Type, Reduce Motion |

### Production Code (create)

| File | Purpose |
|------|---------|
| `HideAndSeekiOS/HideAndSeek/Views/HUDView.swift` | HUD with turns and feedback |
| `HideAndSeekiOS/HideAndSeek/Views/GridView.swift` | Game board grid |
| `HideAndSeekiOS/HideAndSeek/Views/TileButton.swift` | Individual tile with accessibility |
| `HideAndSeekiOS/HideAndSeek/Views/WinView.swift` | Victory overlay |
| `HideAndSeekiOS/HideAndSeek/Views/LoseView.swift` | Game over overlay |
| `HideAndSeekiOS/HideAndSeek/Views/StatsButtonView.swift` | Stats toggle button |
| `HideAndSeekiOS/HideAndSeek/Views/SettingsToggleView.swift` | Settings toggle button |
| `HideAndSeekiOS/HideAndSeek/Views/SettingsSheetView.swift` | Settings sheet with `@Bindable` |

### Test Code (modify)

| File | Change |
|------|--------|
| `HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift` | Adjust for new properties (`revealCount`, `lastRevealedContent`, `isGameOver`) |

---

## Task 1: Update Deployment Target and Swift Version

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj`

- [ ] **Step 1: Update IPHONEOS_DEPLOYMENT_TARGET**

In the pbxproj, search for all instances of `IPHONEOS_DEPLOYMENT_TARGET = 16.0` and replace with `IPHONEOS_DEPLOYMENT_TARGET = 26.0`. This appears in project-level configs (Debug/Release), app target configs (Debug/Release), and test target configs (Debug/Release) — use `replace_all` to catch them all.

- [ ] **Step 2: Update SWIFT_VERSION**

Search for all instances of `SWIFT_VERSION = 5.0` and replace with `SWIFT_VERSION = 6.2`. This appears in app target and test target configs — use `replace_all` to catch them all.

- [ ] **Step 3: Verify build**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: BUILD SUCCEEDED (may have warnings about deprecated APIs — that's expected and will be fixed in later tasks)

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Raise deployment target to iOS 26 and Swift 6.2"
```

---

## Task 2: Migrate GameViewModel to @Observable

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/StatsManager.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/SoundPlaying.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/StatsTracking.swift`
- Modify: `HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift`

- [ ] **Step 0: Address Sendable conformance for managers and protocols**

Under Swift 6.2 strict concurrency, `SoundManager.shared` and `StatsManager.shared` are accessed as default parameters in a `@MainActor` init. Both managers use mutable internal state, so they cannot be `Sendable`. Mark them `@MainActor` to match the ViewModel's isolation:

In `SoundManager.swift`, add `@MainActor` to the class:
```swift
@MainActor
class SoundManager: SoundPlaying {
```

In `StatsManager.swift`, add `@MainActor` to the class:
```swift
@MainActor
class StatsManager: StatsTracking {
```

Update protocols to be `@MainActor`-isolated:

In `SoundPlaying.swift`:
```swift
@MainActor
protocol SoundPlaying {
```

In `StatsTracking.swift`:
```swift
@MainActor
protocol StatsTracking {
```

Update mocks in test files to add `@MainActor` if needed for conformance.

- [ ] **Step 1: Update GameViewModel**

Apply these changes to `GameViewModel.swift`:

1. Add `import Observation` (or it comes via SwiftUI — but this file only imports `Foundation` and `SwiftUI`)
2. Replace `class GameViewModel: ObservableObject {` with `@Observable @MainActor class GameViewModel {`
3. Remove all `@Published` wrappers from properties (just delete the word `@Published`)
4. Add new haptic trigger properties after `celebrateMilestone`:

```swift
    var revealCount = 0
    var lastRevealedContent: ContentType?
    var isGameOver = false
```

5. In `handleTileClick`, after `board[row][col].isRevealed = true`, add:

```swift
        revealCount += 1
        lastRevealedContent = tile.content
```

6. In `handleTileClick`, in the losing condition block (after `gameStatus = .lost`), add:

```swift
            isGameOver = true
```

7. Replace the `DispatchQueue.main.asyncAfter` feedback dismissal:

```swift
// Before:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.feedback = nil
            }

// After:
            Task {
                try? await Task.sleep(for: .seconds(2))
                feedback = nil
            }
```

8. In `resetGame()`, add reset of new properties:

```swift
        isGameOver = false
        revealCount = 0
        lastRevealedContent = nil
```

- [ ] **Step 2: Update tests**

In `GameViewModelTests.swift`, no structural changes needed — the `@MainActor struct` annotation already handles actor isolation. The tests will continue to work because `@Observable` classes are still classes with mutable properties.

If there are any compilation errors from the `@Observable` migration (unlikely since tests access properties directly), fix them.

- [ ] **Step 3: Verify build and tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/ViewModels/GameViewModel.swift \
       HideAndSeekiOS/HideAndSeekTests/GameViewModelTests.swift
git commit -m "Migrate GameViewModel to @Observable with @MainActor"
```

---

## Task 3: Update ContentView and Extract View Files

This is the largest task. Extract 8 view types from ContentView.swift into individual files, applying all modern APIs during extraction.

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/Views/ContentView.swift` (trim to owner view)
- Create: 8 new view files (see below)
- Modify: `HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj` (add new files)

**Global replacements to apply in every extracted file:**
- `@ObservedObject var viewModel: GameViewModel` → `var viewModel: GameViewModel`
- `foregroundColor(` → `foregroundStyle(`
- `.cornerRadius(N)` → `.clipShape(.rect(cornerRadius: N))`
- All hardcoded `.font(.system(size:))` → semantic Dynamic Type fonts per the mapping table in the spec

- [ ] **Step 1: Create `HUDView.swift`**

```swift
import SwiftUI

struct HUDView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                let turnsLabel = Text("Turns: ").foregroundStyle(.white)
                let turnsValue = Text("\(viewModel.turns)")
                    .foregroundStyle(viewModel.turns <= 3 ? .red : .white)
                Text("\(turnsLabel)\(turnsValue)")
                    .font(.title3.bold())

                Spacer()
            }
            .padding(.horizontal)

            Group {
                if let feedback = viewModel.feedback {
                    Text(feedback.message)
                        .font(.headline)
                        .foregroundStyle(feedback.color)
                } else {
                    Text(" ")
                        .font(.headline)
                }
            }
            .frame(minHeight: 28)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
```

- [ ] **Step 2: Create `GridView.swift`**

```swift
import SwiftUI

struct GridView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<viewModel.GRID_SIZE, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<viewModel.GRID_SIZE, id: \.self) { col in
                        TileButton(tile: viewModel.board[row][col], viewModel: viewModel)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
        .accessibilityLabel("Game board")
    }
}
```

- [ ] **Step 3: Create `TileButton.swift`**

```swift
import SwiftUI

struct TileButton: View {
    let tile: Tile
    var viewModel: GameViewModel

    var body: some View {
        Button(action: {
            viewModel.handleTileClick(row: tile.row, col: tile.col)
        }) {
            Text(tile.isRevealed ? tile.contentEmoji(friendPos: viewModel.friendPos) : tile.terrain.rawValue)
                .font(.title2.bold())
                .frame(width: 35, height: 35)
                .background(tile.isRevealed ? Color(red: 0.2, green: 0.45, blue: 0.2).opacity(0.7) : Color(red: 0.25, green: 0.5, blue: 0.25))
                .clipShape(.rect(cornerRadius: 6))
        }
        .disabled(tile.isRevealed || viewModel.gameStatus != .playing)
        .accessibilityLabel(tileAccessibilityLabel)
        .accessibilityHint(tile.isRevealed || viewModel.gameStatus != .playing ? "" : "Tap to reveal this tile")
    }

    private var tileAccessibilityLabel: String {
        if tile.isRevealed {
            switch tile.content {
            case .empty: return "Empty tile"
            case .friend: return "Friend found"
            case .coin: return "Coin"
            case .trap: return "Trap"
            case .compass: return "Compass pointing \(tile.contentEmoji(friendPos: viewModel.friendPos))"
            }
        } else {
            return "\(tile.terrain.rawValue) terrain, row \(tile.row + 1), column \(tile.col + 1)"
        }
    }
}
```

- [ ] **Step 4: Create `WinView.swift`**

```swift
import SwiftUI

struct WinView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("🎉 Victory! 🎉")
                .font(.title2.bold())
            Text("You found your friend with \(viewModel.turns) turns remaining!")
                .font(.subheadline)
            Button("Play Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)

            Button("Show Stats") {
                viewModel.showStats = true
            }
            .padding()
            .background(Color(red: 0.2, green: 0.45, blue: 0.2))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)
        }
        .padding()
        .background(Color(red: 0.25, green: 0.6, blue: 0.25))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
```

- [ ] **Step 5: Create `LoseView.swift`**

```swift
import SwiftUI

struct LoseView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("💔 Game Over 💔")
                .font(.title2.bold())
            Text("You ran out of turns!")
                .font(.subheadline)
            Button("Try Again") {
                viewModel.resetGame()
            }
            .padding()
            .background(Color(red: 0.15, green: 0.4, blue: 0.15))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
            .font(.headline)
        }
        .padding()
        .background(Color(red: 0.7, green: 0.2, blue: 0.2))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
```

- [ ] **Step 6: Create `StatsButtonView.swift`**

```swift
import SwiftUI

struct StatsButtonView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.showStats.toggle()
            }) {
                HStack {
                    Text("📊 Player Stats")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.showStats ? "▼" : "▶")
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
```

- [ ] **Step 7: Create `SettingsToggleView.swift`**

```swift
import SwiftUI

struct SettingsToggleView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.showSettings.toggle()
            }) {
                HStack {
                    Text("⚙️ Settings / Debug")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.showSettings ? "▼" : "▶")
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .background(Color(red: 0.15, green: 0.4, blue: 0.15))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
```

- [ ] **Step 8: Create `SettingsSheetView.swift`**

```swift
import SwiftUI

struct SettingsSheetView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Game Settings")) {
                    VStack(alignment: .leading) {
                        Text("Starting Turns: \(viewModel.settings.startingTurns)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.startingTurns) },
                            set: { viewModel.settings.startingTurns = Int($0) }
                        ), in: 5...30, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Trap Count: \(viewModel.settings.trapCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.trapCount) },
                            set: { viewModel.settings.trapCount = Int($0) }
                        ), in: 0...20, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Coin Count: \(viewModel.settings.coinCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.coinCount) },
                            set: { viewModel.settings.coinCount = Int($0) }
                        ), in: 0...20, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Compass Count: \(viewModel.settings.compassCount)")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.compassCount) },
                            set: { viewModel.settings.compassCount = Int($0) }
                        ), in: 0...15, step: 1)
                    }
                }

                Section(header: Text("Audio")) {
                    Toggle("Sound Effects", isOn: $viewModel.settings.soundEnabled)

                    VStack(alignment: .leading) {
                        Text("Volume Boost: \(String(format: "%.1fx", viewModel.settings.soundVolume))")
                        Slider(value: Binding(
                            get: { Double(viewModel.settings.soundVolume) },
                            set: { viewModel.settings.soundVolume = Float($0) }
                        ), in: 0.5...10.0, step: 0.5)
                    }
                }

                Section {
                    Button("Apply & Reset Game") {
                        viewModel.applySettings()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 9: Rewrite `ContentView.swift`**

Replace the entire file with the trimmed owner view, adding `sensoryFeedback()` modifiers:

```swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.35, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("🌲 Hide & Seek 🌲")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Find your friend in the wilderness!")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.7))
                }
                .padding(.top, 20)

                HUDView(viewModel: viewModel)

                if viewModel.gameStatus == .won {
                    WinView(viewModel: viewModel)
                }

                if viewModel.gameStatus == .lost {
                    LoseView(viewModel: viewModel)
                }

                GridView(viewModel: viewModel)

                StatsButtonView(viewModel: viewModel)

                SettingsToggleView(viewModel: viewModel)

                VStack(spacing: 4) {
                    Text("Tap tiles to search for your friend 🕵️‍♀️")
                        .font(.caption2)
                    Text("All taps cost 1 turn • Coins 💰: 0 net • Traps 🕸️: -2 • Compass: -1 + hint")
                        .font(.caption2)
                }
                .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.7))
                .padding(.bottom, 10)

                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showStats) {
            StatsView(viewModel: viewModel)
        }
        .overlay {
            if let milestone = viewModel.celebrateMilestone {
                MilestoneView(milestone: milestone, viewModel: viewModel)
            }
        }
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
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 10: Add all new files to pbxproj**

Add PBXFileReference, PBXBuildFile, and Views group entries for all 8 new files: `HUDView.swift`, `GridView.swift`, `TileButton.swift`, `WinView.swift`, `LoseView.swift`, `StatsButtonView.swift`, `SettingsToggleView.swift`, `SettingsSheetView.swift`. Each file needs a PBXFileReference entry, a PBXBuildFile entry in the main target's Sources build phase (`FF0003`), and an entry in the Views group (`EE0006`). Use unique IDs prefixed with `VV` to avoid collisions.

- [ ] **Step 11: Verify build**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 12: Verify tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: All tests pass

- [ ] **Step 13: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/Views/ \
       HideAndSeekiOS/HideAndSeek.xcodeproj/project.pbxproj
git commit -m "Extract ContentView into individual files with modern SwiftUI APIs"
```

---

## Task 4: Modernize StatsView and MilestoneView

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/Views/StatsView.swift`
- Modify: `HideAndSeekiOS/HideAndSeek/Views/MilestoneView.swift`

- [ ] **Step 1: Modernize StatsView**

Apply these changes to `StatsView.swift`:

1. `@ObservedObject var viewModel: GameViewModel` → `var viewModel: GameViewModel`
2. `NavigationView {` → `NavigationStack {`
3. All `foregroundColor(` → `foregroundStyle(` (15 instances)
4. All `.cornerRadius(N)` → `.clipShape(.rect(cornerRadius: N))` (2 instances)
5. `.navigationBarTrailing` → `.topBarTrailing`
6. Replace `StatsManager.shared` calls with a `statsManager` parameter:

```swift
struct StatsView: View {
    var viewModel: GameViewModel
    var statsManager: StatsManager = .shared
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirmation = false
```

Then replace all 4 `StatsManager.shared` calls:
- `StatsManager.shared.getLifetimeStats()` → `statsManager.getLifetimeStats()`
- `StatsManager.shared.getLast10Stats()` → `statsManager.getLast10Stats()`
- `StatsManager.shared.getLast100Stats()` → `statsManager.getLast100Stats()`
- `StatsManager.shared.clearStats()` → `statsManager.clearStats()`

7. Replace hardcoded fonts with Dynamic Type:
   - `.system(size: 14, weight: .bold)` → `.caption.bold()` (section headers)
   - `.system(size: 15)` → `.subheadline` (stats rows)
   - `.system(size: 16, weight: .bold)` → `.subheadline.bold()` (clear button)

8. In `StatsSectionView`, apply same `foregroundStyle` and font replacements.

- [ ] **Step 2: Modernize MilestoneView**

Apply these changes to `MilestoneView.swift`:

1. `@ObservedObject var viewModel: GameViewModel` → `var viewModel: GameViewModel`
2. All `foregroundColor(` → `foregroundStyle(` (4 instances)
3. All `.cornerRadius(N)` → `.clipShape(.rect(cornerRadius: N))` (3 instances)
4. Replace hardcoded fonts:
   - `.system(size: 80)` → keep as-is (decorative trophy emoji)
   - `.system(size: 28, weight: .bold)` → `.title.bold()`
   - `.system(size: 36, weight: .heavy)` → `.largeTitle.weight(.heavy)`
   - `.system(size: 18, weight: .bold)` → `.headline`
5. Add Reduce Motion support:

```swift
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // In body, update the trophy animation:
    Text("🏆")
        .font(.system(size: 80))
        .scaleEffect(showAnimation ? 1.0 : (reduceMotion ? 1.0 : 0.5))
        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: showAnimation)

    // Update the card opacity animation:
    .opacity(showAnimation ? 1.0 : 0)
    .animation(.easeIn(duration: reduceMotion ? 0 : 0.3), value: showAnimation)
```

- [ ] **Step 3: Verify build and tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/Views/StatsView.swift \
       HideAndSeekiOS/HideAndSeek/Views/MilestoneView.swift
git commit -m "Modernize StatsView and MilestoneView with modern APIs and accessibility"
```

---

## Task 5: Modernize SoundManager — Remove UIKit Haptics

**Files:**
- Modify: `HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift`

- [ ] **Step 1: Remove UIKit haptic code**

1. Remove `import UIKit`
2. Remove the three haptic generator properties:

```swift
    // DELETE these:
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
```

3. Remove the `prepare()` calls in `init`:

```swift
    // DELETE these:
    lightImpact.prepare()
    mediumImpact.prepare()
    notificationFeedback.prepare()
```

4. Remove the `playHaptic(for:)` method entirely.

5. Remove the `playHaptic(for: contentType)` call from the `play(for:soundEnabled:volume:)` method.

6. In `playGameOver`, remove the haptic loop (keep only the audio part):

```swift
    func playGameOver(soundEnabled: Bool, volume: Float = 1.0) {
        guard soundEnabled else { return }

        if let player = audioPlayers["failure"] {
            player.volume = min(volume, 10.0)
            player.currentTime = 0
            player.play()
        }
    }
```

7. Add `import AVFoundation` if not already present (it is — line 8). Remove `import UIKit` (line 9).

- [ ] **Step 2: Verify build and tests**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add HideAndSeekiOS/HideAndSeek/Managers/SoundManager.swift
git commit -m "Remove UIKit haptics from SoundManager — now handled by SwiftUI sensoryFeedback"
```

---

## Task 6: Final Verification

- [ ] **Step 1: Run the complete test suite**

Run: `xcodebuild test -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: All tests pass

- [ ] **Step 2: Verify the app builds**

Run: `xcodebuild build -project HideAndSeekiOS/HideAndSeek.xcodeproj -scheme HideAndSeek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: BUILD SUCCEEDED with no warnings

- [ ] **Step 3: Verify no deprecated API remains**

Search for deprecated patterns:
- `foregroundColor(` — should return 0 results in view files
- `.cornerRadius(` — should return 0 results
- `NavigationView` — should return 0 results
- `@ObservedObject` — should return 0 results in production code
- `@StateObject` — should return 0 results
- `@Published` — should return 0 results
- `.navigationBarTrailing` / `.navigationBarLeading` — should return 0 results
- `DispatchQueue` — should return 0 results
- `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` — should return 0 results
