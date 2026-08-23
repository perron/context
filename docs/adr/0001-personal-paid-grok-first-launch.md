# ADR 0001: Personal paid Grok-first launch

**Status:** Superseded by ADR 0002 on August 23, 2026

## Decision

Ship the first App Store version from Karl Perron's individual Apple Developer membership as a $6.99 one-time purchase. Version 1.0 is a complete browser with a Grok-first home screen, not the full agent-and-harness roadmap described in the original product documents.

Grok opens at grok.com in a normal Context tab. Context does not scrape a Grok session, store a Grok credential, bundle xAI API usage, or claim an OAuth integration that is not implemented. Bookmarks and browsing history stay on the device. Page handoff can copy, share, and open Grok Bot. Current Grok Bot deep links do not route directly to a named teammate, so Context states that limit in the interface.

The source repository is public under MPL-2.0. The app's privacy policy and support page are published from the same repository.

## Consequences

- App Store Connect controls the up-front price; StoreKit code is not required for version 1.0.
- The seller name is Karl's legal individual seller name.
- The app needs a unique personal bundle identifier and distribution signing under Karl's paid team.
- Future agent, relay, OAuth, sync, subscription, and default-browser work stays on the roadmap and must not appear as working UI or App Store claims until implemented and verified.
- Any future data collection requires an updated privacy manifest, website policy, and App Store privacy answers before release.
