## Summary

Describe the change and the problem it solves.

## Testing

- [ ] `xcodebuild build -project Pekis.xcodeproj -scheme Pekis -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" CODE_SIGNING_ALLOWED=NO`
- [ ] `xcodebuild test -project Pekis.xcodeproj -scheme Pekis -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" CODE_SIGNING_ALLOWED=NO`
- [ ] `./scripts/run_swiftlint.sh` (if SwiftLint is installed)
- [ ] Manual validation for the changed flow

## UI Changes

- [ ] Screenshots or screen recording included if the UI changed
- [ ] Not applicable

## CloudKit, Privacy, and Security Notes

- [ ] No secrets, private share URLs, or personal relationship data were added to the diff
- [ ] If the change affects data handling, networking, or permissions, the relevant docs were updated
- [ ] If the change affects CloudKit behavior, it was tested in an iCloud-enabled environment or the limitation is documented

## Checklist

- [ ] I self-reviewed the changes
- [ ] I added or updated tests where appropriate
- [ ] I updated docs where the public behavior changed
- [ ] I kept the implementation aligned with the project's MVVM and service-layer architecture