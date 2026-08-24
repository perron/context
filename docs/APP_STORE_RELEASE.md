# Context 1.0 App Store release

Context 1.0 is a WebKit browser for iPhone and iPad sold as a one-time USD
$6.99 purchase by Topcloud LLC. It has no subscriptions, in-app purchases,
backend, provider OAuth, included AI credits, analytics SDK, autonomous
browsing, or Mac target.

## Review notes

Context includes tabs, an optional iPad sidebar, local bookmarks and history,
Reader, bundled EasyList and EasyPrivacy protection, and an explicit Ask Grok
surface. A user can add their own xAI or other supported provider API key. The
key stays in iOS Keychain. Ask Grok shows the page context and sends it directly
to the selected provider only when the user presses Send. Provider API billing
is separate from consumer subscriptions and from the Context purchase.

Without an API key, the user can copy the reviewed prompt or choose a
destination from the iOS share sheet. Open Grok and Open Grok Bot launch
independent services without transferring the prompt. Post on X opens X's
reviewable web composer and never posts automatically.

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
6. Privacy policy, App Store privacy answers, and review notes describe
   user-directed transfers to the selected AI provider.
7. For App Review, create a separate low-budget xAI project key, add it only to
   App Store Connect's private Review Information, and revoke it after review.
   Never add the review key to the app binary, repository, screenshots, or
   public review notes.
8. For the fastest 1.0 submission, select only the United States storefront
   while the in-app provider-account links remain. Apple's current Guideline
   3.1.1 permits external purchase calls to action in the U.S. storefront but
   restricts them in many other storefronts. Before adding territories, remove
   or region-gate those links and recheck the current rule with App Review.

## App privacy answers for the BYO API build

Use Apple's conservative definition of third-party collection. Declare Other
User Content and Browsing History as linked to the user and used for App
Functionality because a selected AI provider may retain prompts and reviewed
page context under the user's provider account. Tracking is not used. Context
does not send this data to Topcloud. Recheck every supported provider's current
retention controls before answering App Store Connect.

See `third-party/easylist/NOTICE.md` for filter-list attribution. The exact
bundled source revisions are in `app/Resources/ContentRules/manifest.json`.
