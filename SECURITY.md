# Security Policy

## Supported Versions

Pekis is currently maintained as a rolling project. Security fixes are applied to the current `main` branch first.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Historical commits and unmaintained forks | No |

## Reporting a Vulnerability

Do not open public GitHub issues for security reports.

If GitHub private vulnerability reporting is enabled for this repository, use that channel. Otherwise, contact the project maintainer privately before disclosing details publicly.

Please include:

- A clear description of the issue and affected area
- Steps to reproduce or a proof of concept
- The commit, branch, or release where you observed the problem
- The potential impact and any suggested mitigation
- Any logs, screenshots, or crash traces that help triage the report

## Response Expectations

Maintainers will try to:

- Acknowledge valid reports within 5 business days
- Triage severity and affected scope as quickly as possible
- Coordinate a fix and disclosure plan before public release of details

Response times are best-effort and may vary based on maintainer availability.

## Scope Notes

This policy covers vulnerabilities in the code and configuration in this repository, including:

- CloudKit record handling, sharing, and local caching behavior
- Local notification, deep-link, and asset handling paths
- Matchmaking network requests and session coordination code
- Build scripts, CI automation, and dependency usage in the repository

Apple-operated infrastructure such as iCloud, CloudKit, and APNs is outside the direct control of this project. Reports are still welcome when Pekis uses those services incorrectly or exposes application data through its own code or configuration.

## Disclosure Guidance

Please avoid publishing exploit details until maintainers have had a reasonable opportunity to investigate and ship a fix or mitigation.