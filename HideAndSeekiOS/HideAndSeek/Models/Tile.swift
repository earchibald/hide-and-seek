//
//  Tile.swift
//  HideAndSeek
//
//  Created by Hide & Seek Team
//

import Foundation

enum TerrainType: String, CaseIterable {
    case grass = "🌿"
    case trees = "🌲"
    case rocks = "🪨"
    case pond = "💧"

    var variants: [String] {
        switch self {
        case .grass: ["🌿", "🌾", "☘️", "🍀"]
        case .trees: ["🌲", "🌳", "🌴", "🎋"]
        case .rocks: ["🪨", "⛰️", "🗿"]
        case .pond: ["💧", "🌊", "🪷"]
        }
    }

    var accessibilityName: String {
        switch self {
        case .grass: "grass"
        case .trees: "tree"
        case .rocks: "rocks"
        case .pond: "water"
        }
    }
}

enum ContentType: String {
    case empty = "❌"
    case friend = "🕵️‍♀️"
    case coin = "💰"
    case trap = "🕸️"
    case compass = "compass"
}

struct Tile: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    var terrain: TerrainType
    var terrainEmoji: String
    var content: ContentType
    var isRevealed: Bool = false

    init(row: Int, col: Int, terrain: TerrainType, content: ContentType, terrainEmoji: String? = nil, isRevealed: Bool = false) {
        self.row = row
        self.col = col
        self.terrain = terrain
        self.terrainEmoji = terrainEmoji ?? terrain.rawValue
        self.content = content
        self.isRevealed = isRevealed
    }
    
    func contentEmoji(friendPos: Position?) -> String {
        switch content {
        case .friend:
            return ContentType.friend.rawValue
        case .coin:
            return ContentType.coin.rawValue
        case .trap:
            return ContentType.trap.rawValue
        case .empty:
            return ContentType.empty.rawValue
        case .compass:
            // Return directional arrow
            guard let friendPos = friendPos else { return "•" }
            return getDirectionalArrow(to: friendPos)
        }
    }
    
    private func getDirectionalArrow(to friendPos: Position) -> String {
        let deltaRow = friendPos.row - row
        let deltaCol = friendPos.col - col
        
        let angle = atan2(Double(deltaRow), Double(deltaCol)) * (180.0 / .pi)
        
        // Map angle to 8 directional arrows
        if angle >= -22.5 && angle < 22.5 { return "→" }      // E
        if angle >= 22.5 && angle < 67.5 { return "↘" }       // SE
        if angle >= 67.5 && angle < 112.5 { return "↓" }      // S
        if angle >= 112.5 && angle < 157.5 { return "↙" }     // SW
        if abs(angle) >= 157.5 { return "←" }                 // W
        if angle >= -157.5 && angle < -112.5 { return "↖" }   // NW
        if angle >= -112.5 && angle < -67.5 { return "↑" }    // N
        if angle >= -67.5 && angle < -22.5 { return "↗" }     // NE
        
        return "•"
    }
}

struct Position: Equatable {
    let row: Int
    let col: Int
}
