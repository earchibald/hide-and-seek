# Sound Effects & Haptics Design

**Date:** 2026-02-15
**Status:** Approved

## Overview

Add sound effects and haptic feedback to the Hide & Seek iOS game. Each tile type will play a unique sound and haptic pattern when tapped, enhancing the tactile game experience.

## Requirements

### Sound Mapping
- **Empty tile**: Shovel digging sound
- **Trap tile**: Buzzer sound
- **Coin tile**: Coins clinking sound
- **Friend tile**: Victory sound
- **Compass tile**: Ding/chime sound

### User Controls
- Mute/unmute toggle in settings modal
- Haptic feedback with different patterns per tile type

## Architecture

### SoundManager (NEW)
Create a singleton `SoundManager` class to centralize all audio and haptic logic.

**Location:** `HideAndSeek/Managers/SoundManager.swift`

**Responsibilities:**
- Play sounds for each tile content type
- Trigger appropriate haptic feedback
- Respect mute settings from GameSettings
- Support hybrid approach: system sounds + custom audio files

**Technology:**
- `AVFoundation` for custom audio files
- `AudioServicesPlaySystemSound()` for system sounds
- `UIImpactFeedbackGenerator` & `UINotificationFeedbackGenerator` for haptics

### Integration Points

**GameViewModel.handleTileClick()** (lines 109-158)
- After revealing tile and determining content type
- Call `SoundManager.shared.play(for: contentType, soundEnabled: settings.soundEnabled)`

**GameSettings** (Models/GameSettings.swift)
- Add `soundEnabled: Bool = true` property

**SettingsSheetView** (Views/ContentView.swift, lines 219-280)
- Add new "Audio" section with sound toggle
- Already modal via `.sheet()` modifier

## Sound & Haptic Details

### Empty Tile (Shovel Digging)
- **Sound**: System sound ID 1104 (low thud) → custom `shovel.mp3`
- **Haptic**: Light impact (`.light`) - subtle disappointment

### Trap Tile (Buzzer)
- **Sound**: System sound ID 1053 (alert beep) → custom `buzzer.mp3`
- **Haptic**: Notification error (`.error`) - strong warning

### Coin Tile (Clinking)
- **Sound**: System sound ID 1102 (camera shutter) → custom `coins.mp3`
- **Haptic**: Medium impact (`.medium`) - satisfying feedback

### Friend Tile (Victory)
- **Sound**: System sound ID 1111 (ringtone segment) → custom `victory.mp3`
- **Haptic**: Notification success (`.success`) - celebration pattern

### Compass Tile (Ding/Chime)
- **Sound**: System sound ID 1057 (soft beep) → custom `compass.mp3`
- **Haptic**: Light impact (`.light`) - gentle notification

## Implementation Strategy

### Phase 1: System Sounds
1. Create SoundManager with system sound IDs
2. Implement haptic feedback
3. Add settings toggle
4. Integrate into GameViewModel

### Phase 2: Custom Sounds (Future)
- Drop custom .mp3/.caf files into project
- SoundManager automatically prefers custom files over system sounds
- No code changes needed

## File Structure

```
HideAndSeek/
  ├── Managers/              (NEW)
  │   └── SoundManager.swift
  ├── Models/
  │   └── GameSettings.swift (add soundEnabled)
  ├── ViewModels/
  │   └── GameViewModel.swift (integrate SoundManager)
  └── Views/
      └── ContentView.swift (add audio toggle)
```

## Error Handling

- Missing custom sound files → fall back to system sounds
- System sound failures → continue without crashing
- Haptics automatically no-op on unsupported devices

## Testing Plan

1. **Simulator**: Test system sounds and mute toggle
2. **Physical device**: Test full haptic feedback
3. **Edge cases**:
   - Toggle sounds mid-game
   - Rapid tile tapping
   - Game state transitions (won/lost)

## Success Criteria

- Each tile type plays distinct sound + haptic
- Mute toggle works immediately
- No crashes or audio glitches
- Performance remains smooth (60fps)
- Graceful degradation on older devices
