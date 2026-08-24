# Context 1.0 App Store release

Context 1.0 is a WebKit browser for iPhone and iPad sold as a one-time USD
$6.99 purchase by Topcloud LLC. It has no subscriptions, in-app purchases,
backend, provider OAuth, analytics SDK, autonomous browsing, or Mac target.

## Review notes

Context includes tabs, an optional iPad sidebar, local bookmarks and history,
Reader, bundled EasyList and EasyPrivacy protection, and an explicit Ask Grok
handoff. Ask Grok prepares a prompt for the user to review. Context never sends
it automatically: the user must copy it or choose a destination from the iOS
share sheet. Open Grok and Open Grok Bot launch independent services without
transferring the prompt. Post on X opens X's reviewable web composer and never
posts automatically.

## Submission gates

1. Apple completes the Developer Program migration to Topcloud LLC for the
   existing `perron@mac.com` Apple Account.
2. Xcode shows the verified Topcloud LLC team and produces a validated Release
   archive for `com.karlperron.contextbrowser`.
3. TestFlight is exercised on a physical iPhone and iPad.
4. App Store Connect agreements, banking, tax, age rating, privacy answers,
   price, screenshots, support URL, and privacy URL are complete.
5. Any default-browser claim waits for Apple's managed entitlement and proof in
   the signed build.

See `third-party/easylist/NOTICE.md` for filter-list attribution. The exact
bundled source revisions are in `app/Resources/ContentRules/manifest.json`.
