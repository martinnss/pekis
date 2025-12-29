import Combine
import Foundation

@MainActor
final class DateRouletteViewModel: ObservableObject {
    @Published var currentIdea: String = "Ready to Spin?"
    @Published var isSpinning: Bool = false

    func spin() {
        guard !isSpinning, !AppContent.dateIdeas.isEmpty else { return }
        isSpinning = true

        Task {
            for _ in 0..<20 {
                currentIdea = AppContent.dateIdeas.randomElement() ?? currentIdea
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            isSpinning = false
        }
    }
}
