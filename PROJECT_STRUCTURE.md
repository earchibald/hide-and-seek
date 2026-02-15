# Hide & Seek - Complete Project Structure

## Repository Overview

This repository contains both web and iOS implementations of the Hide & Seek game.

```
hide-and-seek/
├── index.html                      # Web version (React + Tailwind)
├── README.md                       # Original game specification
├── INSTRUCTIONS_iOS.md             # iOS setup guide
├── PROJECT_STRUCTURE.md            # This file
│
└── HideAndSeekiOS/                 # iOS implementation
    ├── HideAndSeek.xcodeproj/      # Xcode project
    │   └── project.pbxproj
    │
    ├── HideAndSeek/                # Source code
    │   ├── HideAndSeekApp.swift    # App entry point
    │   │
    │   ├── Models/                 # Data models
    │   │   ├── Tile.swift          # Tile, terrain, content types
    │   │   └── GameSettings.swift  # Game configuration
    │   │
    │   ├── ViewModels/             # Business logic
    │   │   └── GameViewModel.swift # Game state & logic
    │   │
    │   ├── Views/                  # UI components
    │   │   └── ContentView.swift   # Main game interface
    │   │
    │   ├── Assets.xcassets/        # App assets
    │   │   ├── Contents.json
    │   │   └── AppIcon.appiconset/
    │   │       └── Contents.json
    │   │
    │   └── Info.plist              # App configuration
    │
    ├── README.md                   # iOS technical docs
    └── .gitignore                  # Git ignore rules
```

## Platform Comparison

| Feature | Web (index.html) | iOS (HideAndSeekiOS) |
|---------|------------------|----------------------|
| Framework | React 18 | SwiftUI |
| Language | JavaScript | Swift 5.0+ |
| Styling | Tailwind CSS | Native SwiftUI |
| Platform | Browser | iOS 16.0+ |
| Performance | Good | Native (Excellent) |
| Offline | No | Yes |
| App Store | No | Yes |

## Game Mechanics (Both Platforms)

### Grid
- **Size**: 10x10
- **Terrain**: Grass 🌿, Trees 🌲, Rocks 🪨, Ponds 💧

### Content
- **Friend**: 🕵️‍♀️ (1x) - Win condition
- **Coins**: 💰 (10x) - Net 0 turns
- **Traps**: 🕸️ (10x) - Net -2 turns
- **Compasses**: (5x) - Show directional arrows
- **Empty**: ❌ - Net -1 turn

### Turn Costs
- **Base tap**: -1 turn (all tiles)
- **Coin bonus**: +1 turn (total: 0)
- **Trap penalty**: -1 turn (total: -2)
- **Empty penalty**: 0 turn (total: -1)

### Settings
- Starting Turns: 5-30 (default: 15)
- Trap Count: 0-20 (default: 10)
- Coin Count: 0-20 (default: 10)
- Compass Count: 0-15 (default: 5)

## Running the Projects

### Web Version
```bash
# Open index.html in browser
open index.html

# Or serve with Python
python3 -m http.server 8000
open http://localhost:8000
```

### iOS Version
```bash
# Navigate to iOS project
cd HideAndSeekiOS

# Open in Xcode
open HideAndSeek.xcodeproj

# Then press ⌘R to run in simulator
```

## Development

### Web Version
- Single-file HTML with inline React
- No build process required
- CDN dependencies (React, Tailwind)
- Easy to deploy anywhere

### iOS Version
- Native Swift/SwiftUI app
- Xcode project structure
- No external dependencies
- Built for App Store distribution

## Code Statistics

### Web Version (index.html)
- **Total**: ~13,500 characters
- **Language**: JavaScript (React)
- **Lines**: ~395
- **Components**: 1 main component

### iOS Version
- **Total**: ~17,000 characters
- **Language**: Swift
- **Files**: 5 source files
- **Architecture**: MVVM pattern

### File Sizes
```
Web:
  index.html: 13.5 KB

iOS:
  Tile.swift: 2.0 KB
  GameSettings.swift: 0.2 KB
  GameViewModel.swift: 5.2 KB
  ContentView.swift: 9.6 KB
  HideAndSeekApp.swift: 0.2 KB
  project.pbxproj: 13.2 KB
  Total: ~30 KB
```

## Documentation

### Main Documentation
- `README.md` - Game specification and requirements
- `INSTRUCTIONS_iOS.md` - iOS setup guide (6,000+ chars)
- `HideAndSeekiOS/README.md` - iOS technical docs (3,900+ chars)
- `PROJECT_STRUCTURE.md` - This file

### Code Documentation
- Inline comments in all source files
- Function and class documentation
- Architecture explanations

## Git Structure

### Branches
- `main` - Production-ready code
- `copilot/create-hide-and-seek-game` - Development branch

### Commits
1. Initial web implementation
2. Game mechanics fixes
3. UI improvements
4. iOS implementation
5. Documentation

## Future Enhancements

Potential additions for both platforms:
- [ ] Sound effects
- [ ] Animations for tile reveals
- [ ] High score tracking
- [ ] Difficulty levels
- [ ] Tutorial/help screen
- [ ] Color themes
- [ ] Accessibility features

## License & Credits

Hide & Seek: Wilderness Prototype
Created by the Hide & Seek Team

Both implementations follow the same game design and mechanics,
ensuring consistent gameplay across platforms.
