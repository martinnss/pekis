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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.pekisMint)
                    .padding(11)
                    .background(Color.pekisSurface, in: Circle())
                    .overlay(Circle().stroke(Color.pekisHairline, lineWidth: 1))
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.pekisSun)
                Text("\(viewModel.foundWords.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.pekisInk)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.pekisSurface, in: Capsule())
            .overlay(Capsule().stroke(Color.pekisHairline, lineWidth: 1))
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
                .fill(Color.pekisSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.pekisHairline, lineWidth: 1)
        )
        .shadow(color: Color.pekisMint.opacity(0.25), radius: 18, y: 10)
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
            .font(.system(size: 18, weight: .bold, design: .rounded))
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
            .background(isSelected ? Color.pekisCoral : (isFound ? Color.pekisMint.opacity(0.22) : Color.pekisSurfaceSoft))
            .foregroundStyle(isSelected ? .white : (isFound ? Color.pekisMint : .pekisInk))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                Group {
                    if isFound {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(Color.pekisMint)
                    }
                }
            )
    }

    private var wordList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find these words")
                .font(PekisFont.caption())
                .foregroundStyle(.pekisInkSoft)
                .textCase(.uppercase)
            LazyVGrid(columns: wordColumns, spacing: 8) {
                ForEach(viewModel.puzzle.words, id: \.self) { word in
                    wordView(for: word)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cozyCard(accent: .pekisMint, cornerRadius: 24)
    }

    private func wordView(for word: String) -> some View {
        let isFound = viewModel.foundWords.contains(word)
        let backgroundColor = isFound ? Color.pekisMint.opacity(0.16) : Color.pekisSurfaceSoft
        let strokeColor = isFound ? Color.pekisMint.opacity(0.5) : Color.pekisHairline
        let foregroundColor = isFound ? Color.pekisMint : Color.pekisInk

        return Text(word)
            .font(.system(size: 15, weight: .bold, design: .rounded))
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
            .strikethrough(isFound, color: .pekisMint)
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
