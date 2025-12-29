import Foundation

struct GridCoordinate: Hashable, Identifiable {
    let row: Int
    let column: Int

    var id: String { "\(row)-\(column)" }
}

struct WordSearchPuzzle {
    let grid: [[String]]
    let words: [String]
}
