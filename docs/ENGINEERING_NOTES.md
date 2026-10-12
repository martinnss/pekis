# Engineering Notes

The problems below are the ones that took real debugging while building Pekis, written up as symptom, cause, fix and lesson. Each links to the code that resulted. For the overall design, see [ARCHITECTURE.md](../ARCHITECTURE.md).

**Contents**

1. [Tapping an invite link did nothing](#1-tapping-an-invite-link-did-nothing)
2. [Racing the app's own startup](#2-racing-the-apps-own-startup)
3. [Two partners, two databases, one zone](#3-two-partners-two-databases-one-zone)
4. [Joining a share that "doesn't exist yet"](#4-joining-a-share-that-doesnt-exist-yet)
5. [Queries that fail because of schema state, not code](#5-queries-that-fail-because-of-schema-state-not-code)
6. [Synchronized play without a game server](#6-synchronized-play-without-a-game-server)
7. [A widget that never touches the network](#7-a-widget-that-never-touches-the-network)
8. [Surviving a flaky network and a changing iCloud account](#8-surviving-a-flaky-network-and-a-changing-icloud-account)
9. [Trade-offs I made on purpose](#9-trade-offs-i-made-on-purpose)

---

## 1. Tapping an invite link did nothing

**Symptom.** Partner B taps the invite link in iMessage, Pekis opens, and nothing happens. No error, no pairing.

**Cause.** A SwiftUI `WindowGroup` app is scene-based. iOS delivers `userDidAcceptCloudKitShareWith` to the *window scene delegate*, not to the `UIApplicationDelegate` where I had implemented it. On a cold launch the metadata arrives in a third place, `connectionOptions.cloudKitShareMetadata`. The share was silently dropped on both paths.

**Fix.** [`PekisSceneDelegate`](../Pekis/App/PekisSceneDelegate.swift) handles both the warm path and the cold-launch path and forwards to a single, de-duplicated `handleCloudKitShare(_:)` in the app delegate. Failures now surface as an alert instead of a log line.

**Lesson.** When an Apple callback "never fires", check which delegate your app architecture actually routes it to. Silent failure paths deserve a user-visible error.

## 2. Racing the app's own startup

**Symptom.** Opening the app *from* a share link on a cold launch could fail even when the same link worked on a warm launch.

**Cause.** Two races. (a) The share metadata can arrive before SwiftUI has created the `CloudKitService`. (b) Even once it exists, `acceptShare` can run before `setup()` has finished fetching the current user's ID, which acceptance needs.

**Fix.**
- The app delegate buffers the metadata until the service is attached ([`PekisApp.swift`](../Pekis/App/PekisApp.swift)).
- `acceptShare` waits up to 5 seconds for the user ID and then fails with a clear "sign in to iCloud" error rather than hanging ([`waitForCurrentUserID`](../Pekis/Core/Services/CloudKitService.swift)).
- A one-time `hasLoadedInitialState` gate stops the onboarding UI from being torn down and reset by later loading toggles.

**Lesson.** Startup is concurrent. Anything triggered by the OS (links, pushes) must tolerate arriving before your own initialization finishes.

## 3. Two partners, two databases, one zone

**Bug.** Early versions treated the couple zone as if it always lived in the current user's private database, so Partner B's reads and writes targeted the wrong place.

**Cause.** CloudKit sharing means the *same* record zone lives in two different databases depending on who you are. Partner A owns the zone, so it is in their **private** database. Partner B reaches it through their **shared** database, where the zone's `ownerName` is Partner A rather than the current user. Two traps followed:
- `records(matching:)` without a zone only searches the default zone, not the custom `CoupleZone`.
- Change notifications arrive on a different database for each partner, so subscribing to one database means one partner never gets live updates.

**Fix.**
- Every read and write derives the zone from the fetched couple record and routes to the right database with one rule, now a small tested type: [`CoupleDatabaseScope`](../Pekis/Core/Services/CloudKitAccountState.swift). Before this refactor the same ternary was copy-pasted at every call site.
- The app subscribes to **both** databases ([`subscribeToChanges`](../Pekis/Core/Services/CloudKitService+Sharing.swift)).
- Silent pushes fan out through a `Notification` that each feature's view model observes to refetch its own data.

**Lesson.** "Shared" in CloudKit changes *where* data lives, not just who can see it. Making the routing rule a named, tested type turned a recurring bug source into one line.

## 4. Joining a share that "doesn't exist yet"

**Symptom.** Immediately after Partner B accepts the share, fetching the couple record returns nothing.

**Cause.** CloudKit has a propagation delay between `accept()` completing and the shared zone being visible.

**Fix.** [`fetchSharedCoupleAfterAccept`](../Pekis/Core/Services/CloudKitService.swift) retries up to three times, two seconds apart, before concluding the share is missing. When the couple is found, Partner B's ID is registered on it ([`Couple.acceptingPartner`](../Pekis/Core/Models/Couple.swift), unit-tested so it can never overwrite an existing Partner B) and the app asks for a display name.

A related detail: the share uses `publicPermission = .readWrite`. With `.none`, CloudKit only authorizes participants added by Apple ID, so someone tapping an invite *link* is rejected with a permission error.

**Lesson.** Eventual consistency is a UX problem as much as a data problem. Decide how long you will wait, then tell the user something useful when you give up.

## 5. Queries that fail because of schema state, not code

**Symptom.** In a freshly provisioned CloudKit environment, fetching the couple could fail with a "not marked queryable" error even though the same code worked elsewhere.

**Cause.** `CKQuery` needs queryable indexes defined in the CloudKit schema. That is environment state, not something the app controls.

**Fix.** Discovery code ([`CloudKitCoupleDiscovery`](../Pekis/Core/Services/CloudKitCoupleDiscovery.swift)) falls back from a query to a direct record fetch by the cached couple ID. The error is classified as a *configuration* problem with actionable guidance instead of a generic failure, and the zone is created on demand before the first save ([`CloudKitZoneSetup`](../Pekis/Core/Services/CloudKitZoneSetup.swift)).

**Related.** Xcode copies unresolved build settings into `Info.plist` literally (for example the string `$(PEKIS_CLOUDKIT_CONTAINER_ID)`). [`AppConfiguration`](../Pekis/Core/Utilities/AppConfiguration.swift) detects that and falls back to a container derived from the bundle ID instead of crashing on a nonsense identifier.

**Lesson.** Distinguish "my code is wrong" from "my environment is not provisioned" and make the second one diagnosable.

## 6. Synchronized play without a game server

**Goal.** Two people on two phones play the *same* Word Search at the *same* time, with no backend I operate.

**Design.** Don't synchronize the game, synchronize its inputs:
- One short-lived CloudKit record carries a random **seed** and a `scheduledStartAt` timestamp.
- Both devices generate the identical board locally from that seed with a small deterministic generator ([`WordSearchGenerator`](../Pekis/Core/Services/WordSearchGenerator.swift), a linear congruential RNG).
- Both count down to the same wall-clock start time; whoever finishes first reports a result through the same record.

**Why it matters.** The unit tests assert that the same seed always produces the same board and that every word really is placed in it. That property is what makes the design safe, and it is the most heavily tested code in the project (~99% line coverage).

**Limits.** Moment-to-moment tile selection is local, so this is *synchronized* play, not shared authoritative state. That was a deliberate scope decision, see [section 9](#9-trade-offs-i-made-on-purpose).

## 7. A widget that never touches the network

**Goal.** A Home Screen / Lock Screen countdown widget for the reunion date.

**Constraint.** Widget extensions are short-lived, tightly budgeted, and a poor place for network calls.

**Design.** The widget never talks to CloudKit. Whenever the couple changes, the app writes a tiny `CountdownSnapshot` into an **App Group** `UserDefaults` and asks WidgetKit to reload timelines ([`WidgetBridge`](../Pekis/Core/Shared/WidgetBridge.swift), [`PekisSharedData`](../Pekis/Core/Shared/PekisSharedData.swift)). The shared file compiles into both targets, and access to the App Group is guarded so a missing container logs once instead of spamming `CFPrefs` warnings.

**Lesson.** Push data to constrained surfaces instead of letting them pull.

## 8. Surviving a flaky network and a changing iCloud account

**Problem.** Any mobile app that syncs will see transient failures, and iCloud users can sign out or switch accounts while the app is running. Originally a single transient error simply failed, and a sign-out left the app silently broken.

**Retry with backoff.** [`CloudKitRetry`](../Pekis/Core/Services/CloudKitRetry.swift) retries only errors CloudKit documents as transient (`networkUnavailable`, `networkFailure`, `serviceUnavailable`, `requestRateLimited`, `zoneBusy`) with exponential delays (1s, 2s, 4s, capped at 8s). It honors the server's `retryAfterSeconds` hint (also capped). Conflicts and permission errors are *not* retried, so real failures surface immediately. The sleep function is injectable, so the whole policy is unit-tested without waiting.

**Account changes.** The app listens for `CKAccountChanged` and maps the new state through a pure function, [`AccountTransition.determine`](../Pekis/Core/Services/CloudKitAccountState.swift), into one of: *unchanged*, *signed out* (keep cached data, explain why sync stopped), *signed in* (run setup) or *switched account* (wipe local couple data, then set up). The last case is a privacy guarantee: one iCloud user's cached couple must never be shown to another.

**Testing approach.** The CloudKit calls themselves need a signed app and a real container, so the *decisions* were separated from the *I/O* and tested directly (49 unit tests in total, all running without iCloud).

## 9. Trade-offs I made on purpose

| Decision | Why | Where it would break | What I would do next |
| --- | --- | --- | --- |
| **Last-writer-wins** conflict resolution (`.changedKeys`) | Two people, small records, mostly append-only (notes, answers, moments). Simple and predictable. | Both partners edit the same field offline (for example the reunion date) and the later sync silently wins. | Per-field timestamps, then surface a "your partner changed this" prompt. |
| **No custom backend** | Privacy: relationship data stays in the couple's own iCloud. Nothing for me to host, secure or be breached. | Anything needing server logic: push reminders to a partner who is offline, moderation, analytics. | A minimal server limited to signalling, with end-to-end encrypted payloads. |
| **Synchronized, not shared, Word Search** | A game server and live state sync would dwarf the rest of the app for a feature used for minutes at a time. | Fairness disputes (clock skew affects the shared start), cheating, spectating. | Server-time offset estimation before the countdown. |
| **Selective local cache** | Cache only small text data (couple, notes, answers) as a fallback, not a full offline-first store. | Writes while offline are not queued. | An operation queue with replay on reconnect. |
| **CloudKit service stays a concrete class** | Tying tests to `CKDatabase` would need a wrapper layer larger than the logic it protects. | The networked paths (share acceptance, record I/O) are covered by manual testing on devices, not by unit tests. | Introduce a thin database protocol and test those paths with a fake. |

## How it is tested

49 unit tests run in CI without iCloud. Measured line coverage (Xcode, unit tests only):

| Area | Coverage |
| --- | --- |
| Word Search generation | ~99% |
| Retry policy and account-transition logic | ~93–100% |
| Models (records, caching, pairing helpers) | ~64% |
| Whole app target (SwiftUI views dominate the denominator) | ~14% |

The number to take from this is not the total. Views are mostly declarative layout, and the logic that can be wrong without anyone noticing is covered, while the networked CloudKit I/O is the known gap.
