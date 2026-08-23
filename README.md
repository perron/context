# Context

**A private, open-source, Grok-first browser for iPhone and iPad.**

Context is a native SwiftUI browser built on Apple's WebKit. It gives Grok a permanent place in the browsing flow without scraping sessions, storing AI credentials, or pretending a web login is an embedded API integration.

## Context 1.0

The launch scope is deliberately small and real:

- Native WebKit browsing with tabs and iPad sidebar support
- Searchable bookmarks and browsing history stored on device
- EasyList and EasyPrivacy content blocking, including per-site controls
- Reader mode for supported articles
- System page sharing
- A Grok-first home screen and explicit page handoff to Grok Bot
- Local browser preferences with no analytics or tracking SDK
- MPL-2.0 source code

Grok accounts, subscriptions, and conversations are managed by xAI. Grok Bot accounts and conversations are managed by Cursor/Anysphere. Context does not include either service, and it is not affiliated with or endorsed by xAI, X, Cursor, or Anysphere.

The planned US App Store price for version 1.0 is **$6.99 as a one-time purchase**. The App Store listing is not live until Apple accepts the uploaded build and completes review.

## Status

Context 1.0 is being prepared for App Store submission. An unsigned simulator build and the repository checks must pass before a release commit. A signed archive and App Store upload additionally require active distribution benefits on the Apple Developer account.

Future sync, automation, private-mode, default-browser, and account features are not part of version 1.0 and are not represented as working UI.

## Build locally

Requirements:

- Xcode 26 or later
- Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- SwiftLint for the complete local lint gate

Generate the project and open it in Xcode:

```sh
./scripts/bootstrap.sh
open Context.xcodeproj
```

Run package tests, unsigned simulator checks, license checks, and the build gate:

```sh
./scripts/check.sh
```

The Xcode project is generated from `project.yml`; edit that file, then regenerate rather than hand-editing project settings.

## Privacy and support

- [Privacy policy](https://perron.github.io/context/privacy/)
- [Support](https://perron.github.io/context/support/)
- [Security policy](SECURITY.md)

## Open source

Context is licensed under [MPL-2.0](LICENSE). EasyList and EasyPrivacy data retain their upstream notices under `third-party/`.
