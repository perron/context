# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Context is for people who use Grok, X, and Grok Bot as part of their daily work and want to carry useful web context into an assigned AI teammate without first copying material across several apps. The first release is also for privacy-conscious iPhone and iPad users who value a small, inspectable, open-source browser.

## Product Purpose

Context is a native iPhone and iPad browser that makes the current page useful to Grok. It provides real browsing, tabs, local bookmarks and history, content protection, reader extraction, and an explicit handoff that packages the page title, URL, selected or readable text, and the user's task for Grok or Grok Bot. Success means the browser is dependable on its own and the handoff saves meaningful effort without pretending Context owns the user's Grok account or Grok Bot conversations.

## Positioning

Context is Grok-first because the page handoff is a primary browser action, not a generic chatbot bolted onto a browser. The browser remains local and inspectable. The user chooses when content leaves the device and which Grok destination receives it.

## Operating Context

- Native SwiftUI and WebKit on iPhone and iPad.
- The live working copy stays outside iCloud Drive during development.
- Karl builds with Xcode and Cursor Ultra with Grok 4.6.
- The app will be published from Karl Perron's personal Apple Developer membership and sold as a one-time $6.99 purchase.
- The repository will be public under MPL-2.0.

## Capabilities and Constraints

- WebKit is the browser engine.
- Browsing data stays on device unless the user explicitly shares or sends it.
- Context has no analytics or tracking SDK.
- Context must not claim a direct Grok Bot conversation or assigned-bot API until Cursor publishes and Context implements such a contract.
- Grok Bot currently exposes a deep link that opens the app, but no verified public route that starts a named bot with supplied page context. Version 1 therefore prepares a handoff, copies or shares it, and opens Grok Bot for the user.
- Context does not perform autonomous web actions in version 1.
- Default-browser status depends on Apple's entitlement and must not be promised before approval.
- Desktop and Mac browser versions are outside the first release.

## Brand Commitments

- Name: Context.
- Voice: direct, calm, technically honest, and beginner-readable.
- The supplied Comet screenshots are binding interaction and atmosphere references, not assets to copy.
- Context's own visual world is a native dark "night atlas": deep space, restrained stars, warm white type, a single cool interactive tint, and standard iOS materials and controls.
- Do not copy Comet names, logos, proprietary illustrations, or screen-for-screen composition.
- Grok and Grok Bot remain third-party products identified clearly as services from xAI and Cursor.

## Evidence on Hand

- The current SwiftUI/WebKit project and automated tests in this repository.
- Eighteen Comet iPhone screenshots supplied by Karl on August 23, 2026 as feature and interaction references for tabs, actions, settings, assistant entry, bookmarks, history, and onboarding.
- The current Grok Bot desktop app declares `grokbot` and `sand` URL schemes.
- Cursor's current documentation confirms Grok Bot is available on iOS and shares the same account and cloud computer as desktop.
- No approved Context App Store screenshots, customer testimonials, or direct Grok Bot send API exist yet. Future work must not fabricate them.

## Product Principles

1. Be a real browser before being an AI surface.
2. Make Grok handoff explicit, useful, and reversible.
3. Keep claims, privacy behavior, and shipped capability aligned.
4. Prefer native iOS behavior over custom control theater.
5. Ship a focused first release, then earn broader automation.

## Accessibility & Inclusion

Context uses Dynamic Type, VoiceOver labels, 44-point minimum targets, semantic colors, Reduce Motion-aware transitions, and native iOS navigation. Dark Mode is a first-class appearance, and light appearance must remain legible even when the night-atlas home surface is dark.
