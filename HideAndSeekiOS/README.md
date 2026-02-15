# Hide & Seek iOS App

This is the native iOS implementation of the Hide & Seek game, built with Swift and SwiftUI.

## Requirements

- macOS with Xcode 15.0 or later
- iOS 16.0+ deployment target
- Xcode Command Line Tools installed

## Project Structure

```
HideAndSeekiOS/
├── HideAndSeek.xcodeproj/         # Xcode project file
│   └── project.pbxproj             # Project configuration
└── HideAndSeek/                    # Source code
    ├── HideAndSeekApp.swift        # Main app entry point
    ├── Models/                     # Data models
    │   ├── Tile.swift              # Tile and terrain types
    │   └── GameSettings.swift      # Game configuration
    ├── ViewModels/                 # Game logic
    │   └── GameViewModel.swift     # Main game state and logic
    ├── Views/                      # UI components
    │   └── ContentView.swift       # Main game view
    ├── Assets.xcassets/            # App assets
    └── Info.plist                  # App configuration
```

## Game Mechanics

The iOS app implements the same mechanics as the web version:

- **10x10 Grid**: Random terrain (grass, trees, rocks, ponds)
- **Hidden Content**: 1 friend, 10 coins, 10 traps, 5 compasses
- **Turn System**: Start with 15 turns
- **Tap Costs**:
  - Base tap: -1 turn
  - Coin: +1 turn (net 0)
  - Trap: -1 turn (net -2)
  - Empty: 0 turn (net -1)
  - Compass: Shows directional arrow to friend
- **Win**: Find the friend 🕵️‍♀️
- **Lose**: Run out of turns

## How to Run in Xcode Simulator

### Option 1: Using Xcode GUI

1. Open the project:
   ```bash
   cd HideAndSeekiOS
   open HideAndSeek.xcodeproj
   ```

2. In Xcode:
   - Wait for Xcode to index the project
   - Select a simulator from the device dropdown (e.g., "iPhone 15 Pro")
   - Press `⌘R` or click the "Run" button (▶️)

3. The simulator will launch and the app will install automatically

### Option 2: Using Command Line

1. Navigate to the iOS project directory:
   ```bash
   cd /home/runner/work/hide-and-seek/hide-and-seek/HideAndSeekiOS
   ```

2. List available simulators:
   ```bash
   xcrun simctl list devices available
   ```

3. Build and run on a specific simulator:
   ```bash
   # Example for iPhone 15 Pro
   xcodebuild -project HideAndSeek.xcodeproj \
              -scheme HideAndSeek \
              -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
              clean build
   ```

4. Or use the `open` command:
   ```bash
   open HideAndSeek.xcodeproj
   ```

## Settings

The app includes a settings panel (accessible via the ⚙️ button) where you can adjust:

- **Starting Turns**: 5-30 (default: 15)
- **Trap Count**: 0-20 (default: 10)
- **Coin Count**: 0-20 (default: 10)
- **Compass Count**: 0-15 (default: 5)

After adjusting settings, tap "Apply & Reset Game" to start a new game with the new configuration.

## Features

- ✅ Native iOS performance
- ✅ SwiftUI-based modern UI
- ✅ Portrait and landscape support
- ✅ Dark green forest theme
- ✅ Emoji-based graphics (no assets needed)
- ✅ Responsive tap feedback
- ✅ Win/lose overlays
- ✅ Configurable game settings

## Troubleshooting

### "No such file or directory" error
Make sure you're in the correct directory:
```bash
cd /home/runner/work/hide-and-seek/hide-and-seek/HideAndSeekiOS
```

### Xcode can't find the project
Try opening from the command line:
```bash
open HideAndSeek.xcodeproj
```

### Build errors
Clean the build folder in Xcode: `Product > Clean Build Folder` (⇧⌘K)

### Simulator not launching
Try resetting the simulator:
```bash
xcrun simctl erase all
```

## Development Notes

This iOS app is a faithful recreation of the web version, using:
- **SwiftUI** for declarative UI
- **Combine** for reactive state management
- **Swift 5.0+** language features
- **No external dependencies** - pure Swift/SwiftUI

The game logic is identical to the web version, ensuring consistent gameplay across platforms.
