# ADR 0003: Bring-your-own AI API providers

**Status:** Accepted on August 23, 2026

## Decision

Context 1.0 may connect directly to an AI provider only after the user adds
their own API key and presses Send. Grok through the xAI API is the default.
OpenAI, Anthropic, Google Gemini, OpenRouter, Moonshot Kimi, DeepSeek, and
Mistral are optional providers.

API keys are stored as generic passwords in iOS Keychain with
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Keys are not stored in source
code, UserDefaults, browser history, app logs, or a Topcloud service. Model
preferences may use UserDefaults because they are not secrets.

Before the first message, Ask Grok shows the page title, URL, and readable-text
choice. Context sends the reviewed page snapshot and conversation directly to
the selected provider only when the user presses Send. Requests ask the
provider not to retain server-side conversation state when that API offers a
request-level control. The provider's terms, retention, billing, and account
controls still apply.

The existing iOS share sheet, Grok Bot opener, copy action, and reviewable X
composer remain available. Context does not use provider OAuth, sign in to a
consumer AI account, bundle Topcloud API credits, or claim a direct Grok Bot
send contract.

## Consequences

- Grok, ChatGPT, Claude, Gemini, and other consumer subscriptions remain
  separate from API accounts and API billing.
- A Topcloud-owned shared API key must never ship in the app. Any future
  included usage requires a backend gateway, abuse controls, budgets, and a new
  security and privacy review.
- Provider model IDs are editable because model availability changes.
- The privacy policy, App Store review notes, and release checklist must cover
  user-directed AI provider transfers before submission.
- ADR 0001 remains historical. Its no-AI-credential decision is superseded by
  this ADR. Its Grok Bot and X account boundaries remain in force.
