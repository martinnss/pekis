import SwiftUI

struct HomeView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @StateObject private var wordSearchViewModel = WordSearchViewModel()

    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ZStack {
            Color.pekisBackground.ignoresSafeArea()

            // Ambient background blobs
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color.pekisPurple.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animateBlob1 ? -50 : -150, y: animateBlob1 ? -100 : -200)

                    Circle()
                        .fill(Color.pekisLightPurple.opacity(0.3))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: animateBlob2 ? 50 : 180, y: animateBlob2 ? 150 : 50)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animateBlob1.toggle()
                }
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    animateBlob2.toggle()
                }
            }

            if let vm = viewModel {
                mainContent(viewModel: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(cloudKitService: cloudKitService)
            }
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
                    onLoveNote: { viewModel.show(.loveNote) }
                )
            case .wordSearch:
                WordSearchContainerView(
                    viewModel: wordSearchViewModel,
                    onFinish: { score in viewModel.handleWordSearchFinished(score: score) },
                    onExit: { viewModel.show(.dashboard) }
                )
            case .result:
                WordSearchResultView(
                    score: viewModel.lastScore,
                    onRestart: {
                        viewModel.show(.wordSearch)
                        wordSearchViewModel.startGame()
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
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 16)
        .onChange(of: viewModel.screen) { newValue in
            if newValue != .wordSearch {
                wordSearchViewModel.stopGame()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.screen)
    }
}

#Preview {
    HomeView()
        .environmentObject(CloudKitService())
}
