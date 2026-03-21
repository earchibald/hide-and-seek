import Testing
@testable import HideAndSeek

struct TileTests {
    @Test func tileInitializesUnrevealed() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.isRevealed == false)
    }
}
