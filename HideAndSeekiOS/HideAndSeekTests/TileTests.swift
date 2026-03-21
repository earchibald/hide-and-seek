import Testing
@testable import HideAndSeek

struct TileTests {
    @Test func tileInitializesUnrevealed() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.isRevealed == false)
    }

    @Test func contentEmojiFriend() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .friend)
        #expect(tile.contentEmoji(friendPos: nil) == "🕵️‍♀️")
    }

    @Test func contentEmojiCoin() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .coin)
        #expect(tile.contentEmoji(friendPos: nil) == "💰")
    }

    @Test func contentEmojiTrap() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .trap)
        #expect(tile.contentEmoji(friendPos: nil) == "🕸️")
    }

    @Test func contentEmojiEmpty() {
        let tile = Tile(row: 0, col: 0, terrain: .grass, content: .empty)
        #expect(tile.contentEmoji(friendPos: nil) == "❌")
    }

    @Test func contentEmojiCompassReturnsArrow() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        let emoji = tile.contentEmoji(friendPos: Position(row: 0, col: 5))
        #expect(emoji == "↑")
    }

    @Test func compassWithNoFriendPos() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        #expect(tile.contentEmoji(friendPos: nil) == "•")
    }

    struct CompassCase: CustomTestStringConvertible, Sendable {
        let tileRow: Int
        let tileCol: Int
        let friendRow: Int
        let friendCol: Int
        let expectedArrow: String
        let testDescription: String

        var description: String { testDescription }
    }

    static let compassCases: [CompassCase] = [
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 5, friendCol: 9, expectedArrow: "→", testDescription: "East"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 9, expectedArrow: "↘", testDescription: "Southeast"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 5, expectedArrow: "↓", testDescription: "South"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 9, friendCol: 1, expectedArrow: "↙", testDescription: "Southwest"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 5, friendCol: 1, expectedArrow: "←", testDescription: "West"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 1, expectedArrow: "↖", testDescription: "Northwest"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 5, expectedArrow: "↑", testDescription: "North"),
        CompassCase(tileRow: 5, tileCol: 5, friendRow: 1, friendCol: 9, expectedArrow: "↗", testDescription: "Northeast"),
    ]

    @Test(arguments: compassCases)
    func compassDirection(testCase: CompassCase) {
        let tile = Tile(row: testCase.tileRow, col: testCase.tileCol, terrain: .grass, content: .compass)
        let arrow = tile.contentEmoji(friendPos: Position(row: testCase.friendRow, col: testCase.friendCol))
        #expect(arrow == testCase.expectedArrow)
    }

    @Test func compassSamePosition() {
        let tile = Tile(row: 5, col: 5, terrain: .grass, content: .compass)
        let arrow = tile.contentEmoji(friendPos: Position(row: 5, col: 5))
        #expect(arrow == "→")
    }
}
