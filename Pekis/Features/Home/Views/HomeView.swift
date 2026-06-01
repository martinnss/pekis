import SwiftUI

struct HomeView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @StateObject private var wordSearchViewModel = WordSearchViewModel()

    @StateObject private var viewModel: HomeViewModel

    init(cloudKitService: any CloudKitServiceProtocol) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(cloudKitService: cloudKitService))
    }

    var body: some View {
        ZStack {
            Color.pekisBackground.ignoresSafeArea()

            // Ambient background blobs
            BackgroundBlobsView()

            mainContent(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func mainContent(viewModel: HomeViewModel) -> some View {
        Group {
            switch viewModel.screen {
            case .dashboard:
                DashboardView(
                    viewModel: viewModel,
                    onWordSearch: { viewModel.show(.wordSearch) },
                    onTopics: { viewModel.show(.topics) },
                    onDateRoulette: { viewModel.show(.dateRoulette) },
                    onThisOrThat: { viewModel.show(.thisOrThat) },
                    onLoveNote: { viewModel.show(.loveNote) },
                    onMomentShare: { viewModel.show(.momentShare) }
                )
            case .wordSearch:
                WordSearchContainerView(
                    viewModel: wordSearchViewModel,
                    cloudKitService: cloudKitService,
                    onFinish: { score in viewModel.handleWordSearchFinished(score: score) },
                    onExit: { viewModel.show(.dashboard) }
                )
            case .result:
                WordSearchResultView(
                    score: viewModel.lastScore,
                    onRestart: {
                        viewModel.show(.wordSearch)
                    },
                    onExit: { viewModel.show(.dashboard) }
                )
            case .topics:
                TopicGeneratorView(onExit: { viewModel.show(.dashboard) })
            case .dateRoulette:
                DateRouletteView(onExit: { viewModel.show(.dashboard) })
            case .thisOrThat:
                ThisOrThatView(
                    cloudKitService: cloudKitService,
                    onExit: { viewModel.show(.dashboard) }
                )
            case .loveNote:
                LoveNoteView(
                    cloudKitService: cloudKitService,
                    onExit: { viewModel.show(.dashboard) }
                )
            case .momentShare:
                MomentShareView(
                    cloudKitService: cloudKitService,
                    onExit: { viewModel.show(.dashboard) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 16)
        .onChange(of: viewModel.screen) { _, newValue in
            if newValue != .wordSearch {
                wordSearchViewModel.stopGame()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.screen)
    }
}

#Preview {
    HomeView(cloudKitService: CloudKitService())
        .environmentObject(CloudKitService())
}
