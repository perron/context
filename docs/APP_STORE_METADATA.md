# Context 1.0 App Store metadata

This file is the paste-ready English (U.S.) source of truth for App Store
Connect. Recheck the final fields against the submitted binary before review.

## Product page

- App name: `Context Browser`
- Subtitle: `Browse. Block. Ask AI.`
- Primary category: Utilities
- Secondary category: Productivity
- Price: USD $6.99, one-time purchase
- Initial availability: United States only
- Version: 1.0
- Copyright: `2026 Topcloud LLC`
- Release: Manual
- Support URL: `https://perron.github.io/context/support/`
- Marketing URL: `https://perron.github.io/context/`
- Privacy Policy URL: `https://perron.github.io/context/privacy/`

### Promotional text

Browse with WebKit, block common ads and trackers on device, and ask your
choice of AI provider about the page you are viewing. Your API keys stay in
Keychain.

### Description

Context is a native, open-source browser for iPhone and iPad built around a
deliberate AI workflow: browse the web, review the useful page context, and
choose when to send it.

BROWSE NATIVELY

Use WebKit browsing, multiple tabs, bookmarks, searchable history, Reader,
page sharing, and layouts designed for both iPhone and iPad.

QUIET THE PAGE

Bundled EasyList and EasyPrivacy rules block many common ads and trackers on
your device. Protection can be turned off for an individual website whenever
it interferes with the page.

ASK YOUR CHOICE OF AI

Add your own API key for xAI, OpenAI, Anthropic, Google Gemini, OpenRouter,
Kimi, DeepSeek, or Mistral. Before you press Send, Context shows the page title,
URL, and optional readable text that will accompany your question.

KEEP CONTROL

API keys are stored in iOS Keychain and are sent directly to the provider you
select. Context has no AI relay, advertising SDK, analytics SDK, or developer
account system. Bookmarks and browser history stay on your device.

SHARE WHEN YOU PREFER

You can copy the reviewed prompt, use the iOS share sheet, open Grok or Grok
Bot separately, or open a reviewable X composer. Context never posts
automatically.

Context is a one-time purchase with no Context subscription and no included AI
credits. AI API accounts, consumer subscriptions, and provider usage charges
are separate. Context is independent and is not affiliated with or endorsed by
xAI, X, OpenAI, Anthropic, Google, OpenRouter, Moonshot AI, DeepSeek, Mistral
AI, Cursor, or Anysphere.

### Keywords

`web,browser,assistant,reader,adblock,privacy,tabs,bookmarks,history,search,opensource`

## Age rating questionnaire

- Unrestricted web access: Yes
- Social media: No app-owned social network; users can browse the open web
- User-generated content: No app-owned feed or hosting; users can browse the
  open web
- Messaging/chat: AI provider conversations only, initiated by the user
- Advertising: No ads served by Context
- Gambling, contests, loot boxes: None
- Expected global rating: 16+ because Apple classifies unrestricted web access
  in the 16+ capability tier

Answer every remaining content-frequency question truthfully as `None` unless
the final binary adds that content. App Store Connect calculates the final
regional ratings.

## App privacy answers

Context does not collect data for Topcloud and does not track users. For the
optional, user-directed AI feature, use the conservative third-party-partner
disclosure below because the selected provider may retain data under the
user's provider account:

| Data type | Collected | Linked to identity | Tracking | Purpose |
| --- | --- | --- | --- | --- |
| Other User Content | Yes | Yes | No | App Functionality |
| Browsing History | Yes | Yes | No | App Functionality |

Explain in the privacy policy that Topcloud does not receive this data and that
the transfer occurs only after the user reviews the context and presses Send.
Do not select analytics, advertising, product personalization, or developer
marketing.

## Export compliance

The app uses HTTPS and Keychain encryption supplied by Apple's operating
system. `ITSAppUsesNonExemptEncryption` is `NO` in the generated Info.plist.
Reconfirm the final dependency graph contains no proprietary cryptography before
submission.

## App Review information

### Notes for Review

Context is a native WebKit browser. Its core browser features work without an
account or AI API key.

To review the optional bring-your-own-AI workflow:

1. Open Context and tap the More button (three dots).
2. Open Settings > AI Providers > Grok (xAI API).
3. Paste the temporary, low-budget xAI API key supplied privately in this App
   Review Information and tap Save and use.
4. Browse to a page, tap Ask Grok, review the page title, URL, and readable-text
   switch, enter a question, and tap Send.
5. The key is stored in iOS Keychain and the request goes directly from the
   device to xAI. Topcloud operates no relay and does not receive the key,
   prompt, page context, or response.

Other providers are optional alternatives that require the reviewer's own
provider key. Consumer AI subscriptions are separate from provider API billing.
Context has no in-app purchases, subscriptions, included AI credits, automatic
posting, provider OAuth, or hidden account system.

The reviewer can also test Copy prompt and the iOS share sheet without any API
key. Open Grok, Open Grok Bot, and Post on X launch separate, user-controlled
destinations and never transfer or publish content automatically.

### Private review credential handling

- Create a dedicated xAI project with a small hard spending limit.
- Put its temporary API key only in private App Review Information.
- Never place it in product-page metadata, screenshots, the app binary, source
  control, CI, email, or support tickets.
- Revoke it as soon as review finishes.

## Screenshot order

The candidate pack contains six truthful screens for each required display
size. Upload them in this order:

### iPhone 6.9-inch

1. New tab
2. Grok API context review
3. AI provider settings
4. Protection menu
5. Reader
6. Privacy and filter attribution

### iPad 13-inch

1. New tab with the sidebar expanded
2. New tab with the sidebar collapsed and the visible Show tabs control
3. Grok API context review
4. AI provider settings
5. Protection menu
6. Reader

These are unmodified simulator captures from the tested candidate build. Before
upload, confirm the final signed binary is visually identical. Recapture any
screen that changes. Do not display an API key, personal browsing history,
personal accounts, copyrighted editorial content, or claims that Context
includes provider access.
