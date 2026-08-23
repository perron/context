#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
missing_headers=""

for source_file in $(find \
  "$repo_root/app" \
  "$repo_root/packages/BrowserKit" \
  "$repo_root/packages/SearchKit" \
  "$repo_root/scripts" \
  -type f \
  -not -path '*/.build/*' \
  \( -name '*.swift' -o -name '*.sh' \)); do
  if ! head -8 "$source_file" | grep -q "Mozilla Public"; then
    missing_headers="${missing_headers}${source_file}
"
  fi
done

if [ -n "$missing_headers" ]; then
  echo "Missing MPL-2.0 headers:"
  echo "$missing_headers"
  exit 1
fi
