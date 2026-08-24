#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/context-content-rules.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

curl --fail --silent --show-error --location --retry 3 \
  https://easylist.to/easylist/easylist.txt \
  --output "$temporary_directory/easylist.txt"
curl --fail --silent --show-error --location --retry 3 \
  https://easylist.to/easylist/easyprivacy.txt \
  --output "$temporary_directory/easyprivacy.txt"

grep -q '^! Title: EasyList' "$temporary_directory/easylist.txt"
grep -q '^! Title: EasyPrivacy' "$temporary_directory/easyprivacy.txt"
grep -Eq '^! Licen[cs]e:' "$temporary_directory/easylist.txt"
grep -Eq '^! Licen[cs]e:' "$temporary_directory/easyprivacy.txt"

install -m 0644 \
  "$temporary_directory/easylist.txt" \
  "$repo_root/third-party/easylist/easylist.txt"
install -m 0644 \
  "$temporary_directory/easyprivacy.txt" \
  "$repo_root/third-party/easylist/easyprivacy.txt"

"$repo_root/scripts/compile-content-rules.swift" \
  "$repo_root/third-party/easylist/easylist.txt" \
  "$repo_root/third-party/easylist/easyprivacy.txt" \
  "$repo_root/filters/context.txt" \
  "$repo_root/app/Resources/ContentRules"
