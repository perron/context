# Security

## Report a vulnerability

Email karl@topcloud.com. Do not open a public issue for a suspected
vulnerability.

Include the affected version, reproduction steps, impact, and any suggested
mitigation. We will acknowledge a report within three business days and aim
for coordinated disclosure within 90 days.

## Supported versions

Context is pre-release software. Security fixes apply to the current main
branch until versioned releases begin.

## Boundaries

Context never needs passwords, payment fields, CAPTCHA responses, or browser
cookies for its Grok handoff. A request for any of these is outside the product
contract and should be reported.

User-supplied AI API keys are stored in iOS Keychain with this-device-only,
when-unlocked accessibility. They must never be committed, logged, copied into
UserDefaults, added to browser history, or embedded in a release build. Context
sends a key only to the HTTPS endpoint belonging to the provider selected by
the user.

A Topcloud-owned shared provider key must not ship in the client app. Included
AI usage requires a backend gateway and a separate security review.
