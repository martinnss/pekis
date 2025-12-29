import Foundation

struct LinearCongruentialGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}

enum WordSearchGenerator {
    enum Direction: CaseIterable {
        case horizontal, vertical, diagonalDownRight, diagonalUpRight
        case horizontalBackwards, verticalBackwards, diagonalUpLeft, diagonalDownLeft

        var dx: Int {
            switch self {
            case .horizontal, .horizontalBackwards: return 0
            case .vertical: return 1
            case .verticalBackwards: return -1
            case .diagonalDownRight, .diagonalDownLeft: return 1
            case .diagonalUpRight, .diagonalUpLeft: return -1
            }
        }

        var dy: Int {
            switch self {
            case .horizontal: return 1
            case .horizontalBackwards: return -1
            case .vertical, .verticalBackwards: return 0
            case .diagonalDownRight, .diagonalUpRight: return 1
            case .diagonalDownLeft, .diagonalUpLeft: return -1
            }
        }
    }

    static func makePuzzle(
        gridSize: Int = AppContent.gridSize,
        wordPool: [String] = AppContent.wordPool,
        targetWordCount: Int = 6,
        seed: UInt64? = nil
    ) -> WordSearchPuzzle {
        // Use the provided seed, or a random one if nil
        var rng = LinearCongruentialGenerator(seed: seed ?? UInt64(Date().timeIntervalSince1970 * 1000))

        var grid = Array(repeating: Array(repeating: "", count: gridSize), count: gridSize)
        var selectedWords: [String] = []
        let shuffled = wordPool.shuffled(using: &rng)

        for word in shuffled {
            guard selectedWords.count < targetWordCount else { break }
            var placed = false
            var attempts = 0

            while !placed && attempts < 100 {
                let direction = Direction.allCases.randomElement(using: &rng)!
                let row = Int.random(in: 0..<gridSize, using: &rng)
                let column = Int.random(in: 0..<gridSize, using: &rng)

                if canPlace(word: word, in: grid, at: row, column: column, direction: direction) {
                    place(word: word, in: &grid, at: row, column: column, direction: direction)
                    selectedWords.append(word)
                    placed = true
                }

                attempts += 1
            }
        }

        fillEmptySlots(in: &grid, using: &rng)
        return WordSearchPuzzle(grid: grid, words: selectedWords)
    }

    private static func canPlace(word: String, in grid: [[String]], at row: Int, column: Int, direction: Direction) -> Bool {
        let gridSize = grid.count
        let wordLength = word.count

        // Check bounds
        let endRow = row + (direction.dx * (wordLength - 1))
        let endCol = column + (direction.dy * (wordLength - 1))

        guard endRow >= 0 && endRow < gridSize && endCol >= 0 && endCol < gridSize else { return false }

        for offset in 0..<wordLength {
            let currentRow = row + (direction.dx * offset)
            let currentCol = column + (direction.dy * offset)
            let target = grid[currentRow][currentCol]
            let character = String(word[word.index(word.startIndex, offsetBy: offset)])

            if !target.isEmpty && target != character { return false }
        }

        return true
    }

    private static func place(word: String, in grid: inout [[String]], at row: Int, column: Int, direction: Direction) {
        for offset in 0..<word.count {
            let currentRow = row + (direction.dx * offset)
            let currentCol = column + (direction.dy * offset)
            let character = String(word[word.index(word.startIndex, offsetBy: offset)])
            grid[currentRow][currentCol] = character
        }
    }

    private static func fillEmptySlots(in grid: inout [[String]], using rng: inout LinearCongruentialGenerator) {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
        for rowIndex in grid.indices {
            for columnIndex in grid[rowIndex].indices {
                if grid[rowIndex][columnIndex].isEmpty {
                    grid[rowIndex][columnIndex] = letters.randomElement(using: &rng) ?? "A"
                }
            }
        }
    }
}
