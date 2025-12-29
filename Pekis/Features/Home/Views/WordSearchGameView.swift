import SwiftUI

struct WordSearchGameView: View {
    @ObservedObject var viewModel: WordSearchViewModel
    let onFinish: (Int) -> Void
    let onExit: () -> Void

    @State private var didReportResult = false
    @State private var cellFrames: [GridCoordinate: CGRect] = [:]

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: AppContent.gridSize)
    private let wordColumns: [GridItem] = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        VStack(spacing: 16) {
            header
            gridSection
            wordList
        }
        .padding(.vertical, 8)
        .onAppear {
            didReportResult = false
        }
        .onChange(of: viewModel.allWordsFound) { completed in
            if completed {
                viewModel.stopGame()
                handleCompletionIfNeeded(force: true)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.selection()
                viewModel.stopGame()
                onExit()
            }) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("\(viewModel.foundWords.count)")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    private var gridSection: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<(AppContent.gridSize * AppContent.gridSize), id: \.self) { index in
                let row = index / AppContent.gridSize
                let col = index % AppContent.gridSize
                let coordinate = GridCoordinate(row: row, column: col)
                cellView(for: coordinate)
            }
        }
        .padding(16)
        .coordinateSpace(name: "WordSearchGrid")
        .background(
            GeometryReader { _ in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("WordSearchGrid"))
                            .onChanged { value in
                                handleDrag(at: value.location)
                            }
                            .onEnded { _ in
                                viewModel.finishSelection()
                                handleCompletionIfNeeded()
                            }
                    )
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.pekisPurple.opacity(0.2), radius: 18, y: 10)
        .onPreferenceChange(GridCellPreferenceKey.self) { preferences in
            for p in preferences {
                cellFrames[p.coordinate] = p.frame
            }
        }
    }

    private func cellView(for coordinate: GridCoordinate) -> some View {
        let letter = viewModel.puzzle.grid[coordinate.row][coordinate.column]
        let isSelected = viewModel.selection.contains(coordinate)
        let isFound = viewModel.foundCoordinates.contains(coordinate)

        return Text(letter)
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: GridCellPreferenceKey.self,
                            value: [GridCellPreferenceData(coordinate: coordinate, frame: proxy.frame(in: .named("WordSearchGrid")))]
                        )
                }
            )
            .background(isSelected ? Color.pekisPurple : (isFound ? Color.green.opacity(0.15) : Color.white.opacity(0.1)))
            .foregroundStyle(isFound ? Color.green : .white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                Group {
                    if isFound {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(Color.green)
                    }
                }
            )
    }

    private var wordList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find these words")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .textCase(.uppercase)
            LazyVGrid(columns: wordColumns, spacing: 8) {
                ForEach(viewModel.puzzle.words, id: \.self) { word in
                    wordView(for: word)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func wordView(for word: String) -> some View {
        let isFound = viewModel.foundWords.contains(word)
        let backgroundColor = isFound ? Color.white.opacity(0.1) : Color.white.opacity(0.05)
        let strokeColor = isFound ? Color.green.opacity(0.4) : Color.white.opacity(0.1)
        let foregroundColor = isFound ? Color.green : Color.white

        return Text(word)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .strikethrough(isFound, color: .green)
    }

    private func handleCompletionIfNeeded(force: Bool = false) {
        guard !didReportResult else { return }
        if force || viewModel.allWordsFound == true {
            didReportResult = true
            onFinish(viewModel.foundWords.count)
        }
    }

    private func handleDrag(at location: CGPoint) {
        guard let coordinate = cellFrames.first(where: { $0.value.contains(location) })?.key else { return }

        if viewModel.selection.isEmpty {
            HapticManager.selection()
            viewModel.startSelection(at: coordinate)
        }
        viewModel.updateSelection(to: coordinate)
    }
}

#Preview {
    WordSearchGameView(
        viewModel: WordSearchViewModel(),
        onFinish: { _ in },
        onExit: {}
    )
}

struct GridCellPreferenceData: Equatable {
    let coordinate: GridCoordinate
    let frame: CGRect
}

struct GridCellPreferenceKey: PreferenceKey {
    static var defaultValue: [GridCellPreferenceData] = []

    static func reduce(value: inout [GridCellPreferenceData], nextValue: () -> [GridCellPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}
