import CloudKit
import Foundation

/// What the app should do after the iCloud account changes underneath it.
enum AccountTransition: Equatable {
    /// Nothing to do (same account, or the new account's identity isn't known yet).
    case unchanged
    /// iCloud is unavailable (signed out, restricted, or no account): keep cached data and tell the user.
    case signedOut
    /// An account became available and the app had no identity yet: run setup.
    case signedIn
    /// A different iCloud user signed in: previous couple data must not leak into the new account.
    case switchedAccount

    static func determine(previousUserID: String?, status: CKAccountStatus, currentUserID: String?) -> AccountTransition {
        guard status == .available else { return .signedOut }
        guard let currentUserID else { return .unchanged }
        guard let previousUserID else { return .signedIn }
        return previousUserID == currentUserID ? .unchanged : .switchedAccount
    }
}

/// Which CloudKit database holds a zone.
///
/// Partner A owns the couple zone (private database). Partner B reaches the same zone through
/// the shared database, where the zone's owner is Partner A rather than the current user.
enum CoupleDatabaseScope: Equatable {
    case privateDatabase
    case sharedDatabase

    static func scope(for zoneID: CKRecordZone.ID) -> CoupleDatabaseScope {
        zoneID.ownerName == CKCurrentUserDefaultName ? .privateDatabase : .sharedDatabase
    }
}
