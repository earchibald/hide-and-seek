//
//  HideAndSeekApp.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import SwiftUI

@main
struct HideAndSeekApp: App {
    init() {
        // Preload sound manager to avoid delay on first sound
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
