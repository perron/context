# ADR 0002: Topcloud LLC App Store publisher

**Status:** Accepted on August 23, 2026

## Decision

Publish Context through the Topcloud LLC Apple Developer organization membership. Use `karl@topcloud.com` for public product support and the private App Review contact email. Keep the planned $6.99 one-time App Store price.

The Xcode project does not commit a development team identifier. Karl selects the verified Topcloud LLC team in Xcode after the organization account appears under Xcode Settings and Accounts. This avoids tying the public project to an obsolete or unverified signing team.

The existing bundle identifier remains `com.karlperron.contextbrowser` unless Apple reports that the Topcloud LLC team cannot register or transfer it.

## Consequences

- The App Store seller is Topcloud LLC, subject to Apple's verified legal-entity display.
- Signing certificates, identifiers, profiles, agreements, tax, and banking belong to the Topcloud LLC account.
- Public support, privacy, product, and App Store metadata name Topcloud LLC.
- ADR 0001 remains as project history but is superseded for publisher and signing decisions.
