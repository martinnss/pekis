import XCTest
@testable import Pekis

@MainActor
final class WordSearchTests: XCTestCase {
    func testGeneratorDirections() {
        // Generate many puzzles to ensure we get different directions
        for _ in 0..<10 {
            let puzzle = WordSearchGenerator.makePuzzle(gridSize: 10, wordPool: ["TEST"], targetWordCount: 1)
            if !puzzle.words.isEmpty {
                // We found a word.
                // We can't easily verify direction without exposing more info,
                // but we can verify the word is in the grid.
                let word = puzzle.words[0]
                XCTAssertTrue(findWordInGrid(word, grid: puzzle.grid), "Word \(word) should be in grid")
            }
        }
    }

    func testViewModelDiagonalSelection() async {
        let viewModel = WordSearchViewModel()
        viewModel.startGame()

        // Manually set up a scenario or just test the math
        // Since we can't easily inject a grid into ViewModel (it creates its own),
        // we can test the selection logic if we could mock the start coordinate.
        // But startSelection is public.

        let start = GridCoordinate(row: 0, column: 0)
        let end = GridCoordinate(row: 2, column: 2) // Diagonal

        viewModel.startSelection(at: start)
        viewModel.updateSelection(to: end)

        XCTAssertEqual(viewModel.selection.count, 3)
        XCTAssertTrue(viewModel.selection.contains(GridCoordinate(row: 0, column: 0)))
        XCTAssertTrue(viewModel.selection.contains(GridCoordinate(row: 1, column: 1)))
        XCTAssertTrue(viewModel.selection.contains(GridCoordinate(row: 2, column: 2)))
    }

    func testViewModelUsesProvidedSeedForDeterministicPuzzle() async {
        let seed: UInt64 = 42
        let viewModel = WordSearchViewModel()

        viewModel.startGame(seed: seed)

        let expectedPuzzle = WordSearchGenerator.makePuzzle(seed: seed)
        XCTAssertEqual(renderedGrid(viewModel.puzzle.grid), renderedGrid(expectedPuzzle.grid))
        XCTAssertEqual(viewModel.puzzle.words, expectedPuzzle.words)
    }

    private func renderedGrid(_ grid: [[String]]) -> String {
        grid.map { $0.joined() }.joined(separator: "\n")
    }

    private func findWordInGrid(_ word: String, grid: [[String]]) -> Bool {
        let rows = grid.count
        let cols = grid[0].count
        let dirs = [
            (0, 1), (0, -1), (1, 0), (-1, 0),
            (1, 1), (1, -1), (-1, 1), (-1, -1)
        ]

        for r in 0..<rows {
            for c in 0..<cols {
                for (dx, dy) in dirs {
                    if checkWord(word, grid: grid, r: r, c: c, dx: dx, dy: dy) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private func checkWord(_ word: String, grid: [[String]], r: Int, c: Int, dx: Int, dy: Int) -> Bool {
        let len = word.count
        let rows = grid.count
        let cols = grid[0].count

        // Check bounds
        let endR = r + (len - 1) * dx
        let endC = c + (len - 1) * dy

        if endR < 0 || endR >= rows || endC < 0 || endC >= cols {
            return false
        }

        for i in 0..<len {
            let nr = r + i * dx
            let nc = c + i * dy
            let char = String(word[word.index(word.startIndex, offsetBy: i)])
            if grid[nr][nc] != char {
                return false
            }
        }

        return true
    }
}
