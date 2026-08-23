#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
verify_dir=$(mktemp -d "${TMPDIR:-/tmp}/context-typecheck-XXXXXX")
module_cache="${TMPDIR:-/tmp}/context-swift-module-cache"
platform_developer="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer"

xcrun --sdk iphonesimulator swiftc \
  -module-cache-path "$module_cache" \
  -target arm64-apple-ios26.0-simulator \
  -parse-as-library \
  -emit-module \
  -module-name BrowserKit \
  "$repo_root"/packages/BrowserKit/Sources/*.swift \
  -emit-module-path "$verify_dir/BrowserKit.swiftmodule"

xcrun --sdk iphonesimulator swiftc \
  -module-cache-path "$module_cache" \
  -target arm64-apple-ios26.0-simulator \
  -parse-as-library \
  -emit-module \
  -module-name SearchKit \
  "$repo_root"/packages/SearchKit/Sources/*.swift \
  -emit-module-path "$verify_dir/SearchKit.swiftmodule"

xcrun --sdk iphonesimulator swiftc \
  -module-cache-path "$module_cache" \
  -target arm64-apple-ios26.0-simulator \
  -parse-as-library \
  -enable-testing \
  -emit-module \
  -module-name Context \
  -I "$verify_dir" \
  "$repo_root"/app/Sources/*.swift \
  -emit-module-path "$verify_dir/Context.swiftmodule"

xcrun --sdk iphonesimulator swiftc \
  -module-cache-path "$module_cache" \
  -target arm64-apple-ios26.0-simulator \
  -parse-as-library \
  -I "$platform_developer/usr/lib" \
  -F "$platform_developer/Library/Frameworks" \
  -I "$verify_dir" \
  -typecheck \
  "$repo_root"/app/Tests/*.swift

echo "iOS app and tests type-check passed."
