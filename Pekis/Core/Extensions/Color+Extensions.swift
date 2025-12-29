import SwiftUI

extension Color {
    static let pekisPurple = Color(red: 129/255, green: 38/255, blue: 234/255)
    static let pekisLightPurple = Color(red: 160/255, green: 90/255, blue: 240/255)
    static let pekisDarkPurple = Color(red: 80/255, green: 20/255, blue: 160/255)
    static let pekisBackground = Color(red: 20/255, green: 10/255, blue: 40/255)

    static let pekisGradient = LinearGradient(
        colors: [pekisPurple, pekisDarkPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
