# Privacy

This describes what the Pekis code does with data today. If it ever stops matching the code, please open an issue or a pull request.

## Short version

Relationship data lives in the couple's own iCloud account through CloudKit. I don't run a server that stores it, and the repo contains no analytics, ad or tracking SDKs.

## What the app stores

| Data | Where |
| --- | --- |
| Couple record (partner IDs, names, reunion date) | CloudKit |
| Love notes and This or That answers | CloudKit |
| Daily moment photos | CloudKit, as assets |
| Word Search session (puzzle seed, ready and start times, scores, winner) | CloudKit, short-lived record |
| A copy of the couple, notes and answers | On the device, as a fallback when a fetch fails |
| Countdown snapshot (reunion date, partner name, start date) | On the device, in an App Group shared with the widget |

CloudKit uses the container set in your `.env`. The private and shared databases are used so each partner only sees the couple's data.

The Word Search session record only holds game coordination data. It does not hold notes or photos and is replaced each round.

## What the project does not do

- Run a backend that stores relationship data
- Include analytics, ads or tracking
- Sell or share personal data
- Work fully offline (only a few things are cached)

## Third parties

Pekis relies on Apple services: CloudKit, iCloud sign-in, push notifications and the photo picker. Apple's own privacy terms apply to those.

If the user signs out of iCloud, the app keeps showing its local copy and says that sync has stopped. If a different iCloud user signs in, the app clears the previous user's local couple data first.

## If you contribute

- Don't commit secrets, share links or real relationship data.
- Don't log record contents.
- Blur names, photos and share URLs in screenshots and bug reports.
- Update this file if you add analytics, a new external service, or a new kind of stored data.
