# Player Statistics Tracking Design

**Date:** 2026-02-15
**Status:** Approved

## Overview

Add comprehensive player statistics tracking to the Hide & Seek iOS game, including lifetime stats, recent performance metrics, milestone celebrations, and persistent storage.

## Requirements

### Statistics Tracked
- **Win rate focused approach:**
  - Games played
  - Wins
  - Losses
  - Win rate percentage
  - Current streak (consecutive wins)
  - Best streak (all-time)

### Time Periods
- **Lifetime:** All games ever played
- **Last 10 plays:** Stats from most recent 10 games
- **Last 100 plays:** Stats from most recent 100 games

All three periods show aggregated stats only (no individual game lists).

### Milestone Awards
Celebrate achievements at: **10, 25, 50, 100, 500 wins**

- Full-screen celebration overlay appears after win screen
- Shows trophy, milestone number, "Show Stats" and "Continue Playing" buttons
- Only shows once per milestone (doesn't repeat if replaying)

### Features
- Stats button in main UI (next to Settings)
- Modal stats viewer
- Clear stats button with confirmation
- "Show Stats" button in win screen
- Local storage only (UserDefaults)

## Data Model

### GameStats Structure
```swift
struct GameStats: Codable {
    var gameHistory: [GameResult]  // Last 100 games (FIFO)
    var lifetimeWins: Int
    var lifetimeLosses: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastMilestone: Int?  // Track last celebrated milestone
}

struct GameResult: Codable {
    let won: Bool
    let turnsRemaining: Int
    let date: Date
}

struct StatsData {
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let winRate: Double  // Percentage
    let currentStreak: Int
    let bestStreak: Int
}
```

### Storage
- **Location:** UserDefaults
- **Key:** `"hideAndSeek.playerStats"`
- **Format:** JSON via Codable
- **History:** Keep last 100 games, remove oldest when adding 101st

### Calculated Properties
- **Last 10 stats:** Filter `gameHistory.suffix(10)`
- **Last 100 stats:** Use full `gameHistory`
- **Win rate:** `wins / totalGames * 100`
- **Streak logic:** Increment on win, reset to 0 on loss

## Architecture

### StatsManager (Singleton)
**Location:** `Managers/StatsManager.swift`

**Responsibilities:**
- Load/save stats to UserDefaults
- Maintain game history (last 100)
- Calculate aggregate statistics
- Check for milestone achievements

**Key Methods:**
```swift
class StatsManager {
    static let shared = StatsManager()

    func recordGame(won: Bool, turnsRemaining: Int)
    func getLifetimeStats() -> StatsData
    func getLast10Stats() -> StatsData
    func getLast100Stats() -> StatsData
    func clearStats()
    func checkMilestone() -> Int?  // Returns milestone if reached
}
```

## Integration Points

### GameViewModel
**When game ends (won or lost):**
1. Call `StatsManager.shared.recordGame(won: gameStatus == .won, turnsRemaining: turns)`
2. If won, check for milestone: `if let milestone = StatsManager.shared.checkMilestone()`
3. Set flag to show celebration overlay if milestone exists

**New Published Properties:**
```swift
@Published var showStats = false
@Published var celebrateMilestone: Int? = nil
```

### Game End Flow
```
Game Ends → Record Stats → Check Milestone
           ↓
    If Won: Show WinView
           ↓
    If Milestone: Show MilestoneView overlay
           ↓
    User taps "Show Stats" or "Continue Playing"
```

## UI Components

### Stats Button (ContentView)
- Location: Below Settings button in main view
- Label: "📊 Stats"
- Action: Opens StatsView modal sheet

### StatsView (Modal Sheet)
**Location:** `Views/StatsView.swift`

**Structure:**
```
┌─────────────────────────────────┐
│   Player Statistics        [X]  │
├─────────────────────────────────┤
│ LIFETIME STATS                  │
│ Games: 142 | Wins: 89 | W%: 63% │
│ Best Streak: 12                 │
├─────────────────────────────────┤
│ LAST 10 GAMES                   │
│ Games: 10 | Wins: 7 | W%: 70%   │
│ Current Streak: 3               │
├─────────────────────────────────┤
│ LAST 100 GAMES                  │
│ Games: 100 | Wins: 61 | W%: 61% │
│ Best Streak: 12                 │
├─────────────────────────────────┤
│      [Clear All Stats]          │
└─────────────────────────────────┘
```

**Clear Stats:**
- Red button at bottom
- Shows confirmation alert before clearing
- Alert: "Are you sure? This cannot be undone."

### MilestoneView (Celebration Overlay)
**Location:** `Views/MilestoneView.swift`

**Appearance:**
- Full-screen semi-transparent dark background
- Center card with:
  - 🏆 Trophy emoji (large)
  - "Milestone Achieved!"
  - "{N} Wins!" (e.g., "25 Wins!")
  - "Show Stats" button
  - "Continue Playing" button
- Simple fade-in animation

**Behavior:**
- Appears on top of WinView
- Dismissible via buttons only
- Only shows once per milestone

### WinView Updates
**Location:** `Views/ContentView.swift` (existing WinView)

**Addition:**
- Add "Show Stats" button below "Play Again" button
- Button opens StatsView modal

## File Structure

```
HideAndSeek/
  ├── Models/
  │   ├── GameStats.swift (NEW)
  │   ├── Tile.swift
  │   └── GameSettings.swift
  ├── Managers/
  │   ├── StatsManager.swift (NEW)
  │   └── SoundManager.swift
  ├── Views/
  │   ├── StatsView.swift (NEW)
  │   ├── MilestoneView.swift (NEW)
  │   └── ContentView.swift (modify)
  └── ViewModels/
      └── GameViewModel.swift (modify)
```

## Implementation Order

1. **Create GameStats.swift** - Data models
2. **Create StatsManager.swift** - Logic and persistence
3. **Integrate GameViewModel** - Record wins/losses, check milestones
4. **Create StatsView.swift** - Stats display modal
5. **Create MilestoneView.swift** - Celebration overlay
6. **Update ContentView** - Add stats button
7. **Update WinView** - Add "Show Stats" button
8. **Test milestones** - Verify 10, 25, 50, 100, 500 win celebrations

## Edge Cases & Error Handling

### First Launch
- Initialize empty `GameStats` with zeros
- Create default UserDefaults entry

### Clear Stats
- Show confirmation alert: "Clear all statistics? This cannot be undone."
- Reset all fields to zero
- Clear game history array
- Reset milestone tracker

### Milestone Tracking
- Store `lastMilestone` to prevent re-showing same milestone
- Only celebrate when crossing threshold (e.g., 24→25, not 25→26)
- Handle edge case: user clears stats then rebuilds (milestones can re-trigger)

### Data Migration
- Check for missing fields when loading from UserDefaults
- Provide defaults for any missing properties
- Handle corrupt data gracefully (reset to empty stats)

### Performance
- UserDefaults reads/writes are synchronous - acceptable for this data size
- Keep game history limited to 100 entries to avoid bloat
- Calculate stats on-demand (not pre-computed)

## Success Criteria

✅ Stats persist across app launches
✅ All three time periods display correctly
✅ Milestones trigger at correct win counts
✅ Celebration overlay appears only once per milestone
✅ Clear stats works with confirmation
✅ "Show Stats" accessible from win screen and main UI
✅ Streaks calculated correctly (increment on win, reset on loss)
✅ Win rate percentage accurate to 1 decimal place

## Future Enhancements (Not in Scope)

- Export/import stats as backup
- iCloud sync across devices
- More detailed stats (coins collected, traps hit, etc.)
- Charts/graphs of performance over time
- Additional milestones or achievements
