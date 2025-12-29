import Combine
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class MomentShareViewModel: ObservableObject {
    @Published private(set) var prompt: String
    @Published private(set) var image: UIImage?
    @Published private(set) var isPosted: Bool = false

    init(date: Date = Date()) {
        if AppContent.momentPrompts.isEmpty {
            prompt = "Share a little moment!"
        } else {
            let hourIndex = Calendar.current.component(.hour, from: date) % AppContent.momentPrompts.count
            prompt = AppContent.momentPrompts[hourIndex]
        }
    }

    func updatePickerItem(_ item: PhotosPickerItem?) {
        guard let item else {
            image = nil
            isPosted = false
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            image = uiImage
        }
    }

    func resetPhoto() {
        image = nil
        isPosted = false
    }

    func postMoment() {
        guard image != nil else { return }
        isPosted = true
    }
}
