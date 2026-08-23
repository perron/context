# Contributing to Context

Context accepts focused changes that match `PRODUCT.md` and the shipped app.

## Build

Requirements:

- Xcode 26.0 or later
- XcodeGen 2.44.1 or later
- SwiftLint

Run:

```sh
./scripts/bootstrap.sh
open Context.xcodeproj
```

Before opening a pull request:

```sh
./scripts/check.sh
```

## Pull requests

- Use a focused branch and a conventional commit.
- Include tests for behavior changes.
- Include a simulator screenshot or recording for UI changes.
- Add an MPL-2.0 notice to every new source file.
- Do not add secrets, runtime-downloaded code, or GPL-family dependencies.

All commits must include a Developer Certificate of Origin sign-off:

```text
Signed-off-by: Your Name <you@example.com>
```

By contributing, you certify the contribution under the
[Developer Certificate of Origin 1.1](https://developercertificate.org/).
Context does not use a contributor license agreement.
