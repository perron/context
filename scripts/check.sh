#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
derived_data="${TMPDIR:-/tmp}/context-derived-data"

"$repo_root/scripts/bootstrap.sh"
"$repo_root/scripts/check-licenses.sh"

for package in BrowserKit SearchKit; do
  swift test --disable-sandbox --package-path "$repo_root/packages/$package"
done

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint --strict --config "$repo_root/.swiftlint.yml"
else
  echo "SwiftLint is not installed. Skipping local lint."
fi

"$repo_root/scripts/typecheck-platforms.sh"

xcodebuild \
  -project "$repo_root/Context.xcodeproj" \
  -scheme Context \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build
