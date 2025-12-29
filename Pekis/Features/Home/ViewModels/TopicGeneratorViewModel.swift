import Combine
import Foundation

@MainActor
final class TopicGeneratorViewModel: ObservableObject {
    @Published var currentTopic: String = ""
    @Published var isAnimating: Bool = false

    init() {
        Task { await generateTopic() }
    }

    func generateTopic() async {
        guard !AppContent.topics.isEmpty else { return }
        isAnimating = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        currentTopic = AppContent.topics.randomElement() ?? ""
        isAnimating = false
    }
}
