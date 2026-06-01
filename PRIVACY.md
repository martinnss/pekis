# Privacy

This document describes the current data-handling behavior of the Pekis repository as it exists today. It is intended to help contributors and users understand the app's architecture and privacy boundaries.

## Summary

Pekis is designed so that relationship data lives primarily in the user's own iCloud account through CloudKit, rather than in a custom backend operated by the project maintainer.

At the time of writing:

- Couple data, love notes, This or That answers, and shared photo moments are stored through CloudKit
- Selected shared text data is cached locally on-device for resilience
- Word Search uses CloudKit session metadata for transient ready/start/winner coordination
- Word Search waiting-room state is shared through the same short-lived CloudKit session metadata
- No analytics SDK, ad SDK, or app-tracking framework is present in the repository

## Data the App Handles

Depending on the feature, Pekis can process:

- Couple identifiers and participant names
- Reunion date and pairing state
- Love notes and This or That answers
- Moment Share images uploaded as CloudKit assets
- Local cache entries for selected shared records
- Word Search session metadata used for coordination, such as a generated puzzle seed, ready timestamps, a scheduled start time, scores, and the winner identifier

## Where Data Lives

### 1. User iCloud / CloudKit

Persistent shared relationship data is stored in CloudKit using the app's configured container from `.env`.

The codebase uses CloudKit private and shared databases for:

- Couple pairing and share acceptance
- Love notes
- This or That answers
- Moment Share uploads

### 2. Local Device Storage

The app keeps a selective local cache for some text-based shared state so the UI can recover more gracefully when network fetches fail. The current architecture documents cache support for:

- `Couple`
- `LoveNote`
- `ThisOrThatAnswer`

This is not a blanket offline-first system. Not every feature maintains a full offline cache.

### 3. Shared Word Search Session Metadata

The Word Search feature uses a short-lived CloudKit session record for lightweight coordination. Based on the current implementation, that record stores transient values such as:

- a generated puzzle seed
- partner ready timestamps
- a scheduled start time
- winner and score metadata

This record is used to coordinate readiness, countdown timing, waiting-room state, and winner detection. It is not intended to store love notes, shared photos, or other persistent relationship content beyond the match lifecycle.

## What the Project Does Not Do

Based on the current repository:

- It does not run a custom backend for persistent relationship data
- It does not include ad-tech or tracking SDKs
- It does not sell personal data
- It does not claim full offline parity across all features

## Third Parties and Platform Services

Pekis relies on Apple platform services such as CloudKit, iCloud authentication, push delivery, and photo/media APIs. Those services are governed by Apple's own privacy and platform policies.

Word Search coordination also depends on CloudKit delivery and refresh behavior for transient game-session updates.

## Contributor Expectations

If you contribute to Pekis:

- Do not commit secrets, private share URLs, or personal relationship data
- Avoid logging sensitive record contents in production code
- Keep screenshots or bug reports involving Word Search sessions sanitized so they do not expose partner names, private photos, or CloudKit share details
- Update this document if you add analytics, tracking, new external services, or new categories of stored personal data
- Keep public issue reports sanitized so they do not expose private content or identifiers

## Questions and Corrections

If this document no longer matches the implementation, open a documentation issue or submit a pull request with the relevant code references.