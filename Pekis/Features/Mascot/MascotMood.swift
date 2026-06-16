import SwiftUI

/// Emotional states that drive the Peki mascot's expression and motion.
enum MascotMood: Equatable {
    case idle        // gentle breathing + occasional blink
    case happy       // bigger smile, light bounce
    case waving      // one arm waves hello
    case hopeful     // looking out for a partner (invite sent, waiting)
    case love        // heart eyes + blush
    case engaged     // heart eyes, leaning, the "we're together" peak state
    case celebrate   // excited jump
    case sleepy      // half-closed eyes (loading)

    var showsHeartEyes: Bool { self == .love || self == .engaged }
    var showsBlush: Bool { self == .love || self == .engaged || self == .happy }
    var bobs: Bool { self != .sleepy }
}
