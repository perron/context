# Context

Open-source, Grok-first browser for iPhone and iPad. Version 1 is a focused, native WebKit browser with tabs, content protection, reader extraction, and an explicit page handoff to Grok or Grok Bot. Planned App Store price: $6.99 one-time purchase. Publisher: Karl Perron through his personal Apple Developer membership. MPL-2.0, public repo.

## Project facts (shared section: keep identical in CLAUDE.md)

- Owner and publisher: Karl Perron. He reviews behavior and needs beginner-readable instructions.
- `PRODUCT.md` and `docs/adr/0001-personal-paid-grok-first-launch.md` override older roadmap documents when they conflict.
- Stack: Swift 6, SwiftUI, iOS 26 floor, and WebKit. Alternate browser engines are out of scope.
- Grok and Grok Bot remain third-party services. Never claim an account, chat, named-bot, or send integration that has not been verified against a public contract.
- Non-negotiables: no autonomous web actions in version 1; content leaves the device only on explicit user action; no passwords, payments, or CAPTCHA near AI features; only bundled JavaScript runs; no GPL dependencies; secrets never enter the public repository; MPL header on every source file.
- The first App Store release is iPhone and iPad only. Relay, backend, subscriptions, external purchase links, multiple harnesses, and Mac browser work are future scope unless Karl explicitly restores them.
- Conventional commits, simulator screenshots for UI changes, and automated test gates remain required.

## Writing style (docs, UI copy, PR bodies, release notes)

- No em dashes. Use hyphens or restructure.
- Terse, direct, short sentences. No superlatives, no AI filler, no buzzwords.
- Single strong recommendations, not option lists. `decision-needed` tag for Karl's calls.

## Working with Karl

- He reviews behavior. Screenshots/recordings in every PR; Friday demo is the one meeting.
- Push back when a brief conflicts with the docs; cite the doc section.
- Missing brief: ask for one line of intent in `docs/briefs/`, do not guess scope.
- Everything in the repo is public. No financials, personal data, or vendor negotiations in code, PRs, or issues.
