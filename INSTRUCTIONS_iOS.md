# 🎮 Hide & Seek iOS App - Setup Instructions

## ✅ Project Created Successfully!

Your iOS implementation is ready to run! The project structure is set up with all the game logic, UI components, and Xcode configuration files.

## 📁 What Was Created

```
HideAndSeekiOS/
├── HideAndSeek.xcodeproj/          ← Xcode project file (open this!)
│   └── project.pbxproj
├── HideAndSeek/                     ← Source code
│   ├── HideAndSeekApp.swift        ← App entry point
│   ├── Models/                     ← Data models
│   │   ├── Tile.swift              ← Tile types, terrain, content
│   │   └── GameSettings.swift      ← Game configuration
│   ├── ViewModels/                 ← Game logic
│   │   └── GameViewModel.swift     ← All game state & logic
│   ├── Views/                      ← UI components
│   │   └── ContentView.swift       ← Main game interface
│   ├── Assets.xcassets/            ← App assets
│   └── Info.plist                  ← App configuration
├── README.md                        ← Detailed documentation
└── .gitignore                       ← Git ignore rules
```

## 🚀 Quick Start - Open in Xcode

### Step 1: Navigate to the iOS Project

```bash
cd /home/runner/work/hide-and-seek/hide-and-seek/HideAndSeekiOS
```

### Step 2: Open the Project in Xcode

```bash
open HideAndSeek.xcodeproj
```

This will launch Xcode and open your project!

### Step 3: Select a Simulator

In Xcode:
1. Look at the top toolbar
2. Find the device selector (next to the "Run" button)
3. Click it and select a simulator, for example:
   - **iPhone 15 Pro** (recommended)
   - iPhone 15
   - iPhone 14 Pro
   - iPad Pro (12.9-inch)

### Step 4: Build and Run

Press **⌘R** (Command + R) or click the **▶️ Run** button in the toolbar.

The simulator will launch and your app will install automatically!

## 🎯 Game Features

Your iOS app has all the same features as the web version:

### Core Gameplay
- **10x10 Grid** with random terrain (🌿 grass, 🌲 trees, 🪨 rocks, 💧 ponds)
- **15 Starting Turns** (configurable in settings)
- **Hidden Content:**
  - 1 Friend 🕵️‍♀️ (win condition)
  - 10 Coins 💰 (net 0 turns)
  - 10 Traps 🕸️ (net -2 turns)
  - 5 Compasses (show directional arrows)

### Tap Costs
- **Base cost:** -1 turn for any tap
- **Coin:** +1 turn (net 0 with tap)
- **Trap:** -1 turn (net -2 with tap)
- **Empty:** 0 turn (net -1 with tap)
- **Compass:** Shows arrow pointing to friend

### UI Features
- ✅ Clean dark green forest theme
- ✅ Turn counter with red warning (≤3 turns)
- ✅ Feedback messages (coins, traps, empty)
- ✅ Win/lose overlays
- ✅ Settings panel (⚙️ button)
- ✅ Directional arrows in revealed compass tiles

## ⚙️ Settings Panel

Tap the **⚙️ Settings / Debug** button to adjust:

- **Starting Turns:** 5-30 (default: 15)
- **Trap Count:** 0-20 (default: 10)
- **Coin Count:** 0-20 (default: 10)
- **Compass Count:** 0-15 (default: 5)

After adjusting, tap **"Apply & Reset Game"** to start fresh with new settings.

## 🎨 Design

The iOS app uses:
- **Native SwiftUI** for smooth, responsive UI
- **Emoji graphics** (no image assets needed!)
- **Dark green theme** matching the web version
- **Portrait & landscape** support
- **Touch-optimized** button sizes

## 📱 Testing on Different Devices

The app supports various iOS devices:

### iPhones
- iPhone 15 Pro / Pro Max
- iPhone 15 / Plus
- iPhone 14 Pro / Pro Max
- iPhone 14 / Plus
- iPhone SE (3rd generation)
- And older models back to iOS 16.0

### iPads
- iPad Pro (all sizes)
- iPad Air
- iPad (10th generation)
- iPad mini

## 🔧 Alternative Launch Methods

### Using Command Line (if GUI doesn't work)

1. List available simulators:
```bash
xcrun simctl list devices available | grep iPhone
```

2. Boot a simulator:
```bash
xcrun simctl boot "iPhone 15 Pro"
```

3. Build the project:
```bash
cd HideAndSeekiOS
xcodebuild -project HideAndSeek.xcodeproj \
           -scheme HideAndSeek \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build
```

### Using Xcode from Terminal

```bash
# Open Xcode with the project
cd /home/runner/work/hide-and-seek/hide-and-seek/HideAndSeekiOS
xed .
```

## 🐛 Troubleshooting

### "Cannot find HideAndSeek.xcodeproj"
Make sure you're in the right directory:
```bash
cd /home/runner/work/hide-and-seek/hide-and-seek/HideAndSeekiOS
ls -la
# You should see HideAndSeek.xcodeproj listed
```

### Build Errors in Xcode
1. Clean the build: **Product > Clean Build Folder** (⇧⌘K)
2. Reset simulator: **Device > Erase All Content and Settings...**
3. Restart Xcode

### Simulator Won't Launch
```bash
# Kill all simulators
killall Simulator

# Boot fresh
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
```

### Code Signing Issues
For simulator testing, code signing is automatic. Just select "Automatically manage signing" in project settings if prompted.

## 📚 Code Architecture

The iOS app uses modern Swift patterns:

### Models (`Models/`)
- `Tile.swift` - Defines tile types, terrain, content, and directional arrow logic
- `GameSettings.swift` - Game configuration structure

### ViewModels (`ViewModels/`)
- `GameViewModel.swift` - Contains all game logic:
  - Board generation
  - Tile click handling
  - Turn management
  - Win/lose conditions
  - Settings management

### Views (`Views/`)
- `ContentView.swift` - Main UI with:
  - Header
  - HUD (turns counter + feedback)
  - Grid (10x10 with tiles)
  - Win/lose overlays
  - Settings panel

## 🎓 Learning Resources

If you want to modify the app:

- **SwiftUI Documentation:** [developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui)
- **Swift Language Guide:** [docs.swift.org/swift-book](https://docs.swift.org/swift-book)
- **Xcode Help:** Press ⌘/ in Xcode or visit [developer.apple.com/xcode](https://developer.apple.com/xcode)

## 🎉 You're Ready!

Your Hide & Seek iOS app is complete and ready to run! Just:

1. `cd HideAndSeekiOS`
2. `open HideAndSeek.xcodeproj`
3. Select iPhone simulator
4. Press ⌘R

Have fun playing and testing! 🌲🕵️‍♀️🌲
