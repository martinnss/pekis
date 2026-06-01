import Combine
import Foundation
import UIKit

@MainActor
final class WordSearchViewModel: ObservableObject {
    @Published private(set) var puzzle: WordSearchPuzzle = WordSearchGenerator.makePuzzle()
    @Published private(set) var foundWords: Set<String> = []
    @Published private(set) var foundCoordinates: Set<GridCoordinate> = []
    @Published private(set) var selection: [GridCoordinate] = []
    @Published private(set) var isActive: Bool = false

    private var startCoordinate: GridCoordinate?
    private var lastSelectionCount: Int = 0

    var allWordsFound: Bool {
        foundWords.count == puzzle.words.count && !puzzle.words.isEmpty
    }

    func startGame(seed: UInt64? = nil) {
        // Use the current minute as a seed so both players get the same puzzle
        // and it changes frequently enough for multiple games.
        // TimeIntervalSince1970 is UTC, so it works across time zones.
        let resolvedSeed: UInt64
        if let seed {
            resolvedSeed = seed
        } else {
            let minuteTimestamp = Int(Date().timeIntervalSince1970 / 60)
            resolvedSeed = UInt64(minuteTimestamp)
        }

        puzzle = WordSearchGenerator.makePuzzle(seed: resolvedSeed)
        foundWords.removeAll()
        foundCoordinates.removeAll()
        selection.removeAll()
        startCoordinate = nil
        isActive = true
    }

    func stopGame() {
        isActive = false
        selection.removeAll()
        startCoordinate = nil
    }

    func startSelection(at coordinate: GridCoordinate) {
        guard isActive else { return }
        startCoordinate = coordinate
        selection = [coordinate]
        lastSelectionCount = 1
    }

    func updateSelection(to coordinate: GridCoordinate) {
        guard let startCoordinate = startCoordinate else { return }

        let isHorizontal = coordinate.row == startCoordinate.row
        let isVertical = coordinate.column == startCoordinate.column
        let isDiagonal = abs(coordinate.row - startCoordinate.row) == abs(coordinate.column - startCoordinate.column)

        if isHorizontal || isVertical || isDiagonal {
            selection = coordinatesBetween(startCoordinate, coordinate)

            // Haptic feedback when selection length changes
            if selection.count != lastSelectionCount {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                lastSelectionCount = selection.count
            }
        }
    }

    func finishSelection() {
        guard !selection.isEmpty else { return }

        let selectedWord = selectionWord()
        let reversedWord = String(selectedWord.reversed())

        // Check if the selected word (or its reverse) is in the puzzle words
        // and hasn't been found yet.
        var found: String?

        if puzzle.words.contains(selectedWord) && !foundWords.contains(selectedWord) {
            found = selectedWord
        } else if puzzle.words.contains(reversedWord) && !foundWords.contains(reversedWord) {
            found = reversedWord
        }

        if let found = found {
            foundWords.insert(found)
            foundCoordinates.formUnion(selection)
            triggerSuccessHaptic()
        } else {
            triggerErrorHaptic()
        }

        selection = []
        startCoordinate = nil
        lastSelectionCount = 0
    }

    private func selectionWord() -> String {
        selection.reduce(into: "") { partialResult, coordinate in
            guard puzzle.grid.indices.contains(coordinate.row),
                  puzzle.grid[coordinate.row].indices.contains(coordinate.column) else { return }
            partialResult.append(puzzle.grid[coordinate.row][coordinate.column])
        }
    }

    private func coordinatesBetween(_ start: GridCoordinate, _ end: GridCoordinate) -> [GridCoordinate] {
        var coords: [GridCoordinate] = []

        let dRow = end.row - start.row
        let dCol = end.column - start.column

        let steps = max(abs(dRow), abs(dCol))

        guard steps > 0 else { return [start] }

        let stepRow = dRow / steps
        let stepCol = dCol / steps

        for i in 0...steps {
            coords.append(GridCoordinate(row: start.row + i * stepRow, column: start.column + i * stepCol))
        }

        return coords
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
