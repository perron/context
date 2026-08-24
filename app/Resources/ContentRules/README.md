# Content rule artifacts

Run:

```sh
scripts/compile-content-rules.swift \
  third-party/easylist/easylist.txt \
  third-party/easylist/easyprivacy.txt \
  filters/context.txt \
  app/Resources/ContentRules
```

The converter emits deterministic WebKit JSON from the three checked-in source
lists. Network rules and standard EasyList cosmetic selectors are emitted in
separate shards. Cosmetic rules use WebKit's `css-display-none` action, honor
domain restrictions and standard `#@#` exceptions, and intentionally skip
procedural selector extensions that WebKit cannot compile.

The converter also emits `cosmetic-enforcement.js`. Context injects this
bundled stylesheet into the main document's isolated WebKit content world at
document start with `display: none !important`. It uses the same pinned
selectors and domain exceptions as the WebKit shards. This second layer keeps
dynamically inserted ads hidden when a site loads utility CSS after the native
content blocker. Its narrow observer watches only the direct children of the
element containing its own style. It does not read or transmit page content.

`filters/context.txt` is the small, MPL-licensed supplemental list for verified
site regressions that are not fixed in the pinned upstream lists yet. Keep its
rules narrow, explain each site fix in a comment, and prove changes with a
deterministic UI fixture plus a live-site simulator check.

Each shard stays at or below 40,000 rules, comfortably below WebKit's per-list
ceiling. Network exception rules are repeated at the end of each network shard
so `ignore-previous-rules` applies within the list that contains its blocking
rules. Keeping cosmetic rules in their own shards prevents a network exception
from accidentally disabling page-element cleanup.

To download current upstream lists and regenerate the artifacts in one step,
run `scripts/update-content-rules.sh`. Review the source metadata and generated
diff before committing. Context never updates rules inside the installed app;
new rules ship only in a reviewed app release.

The app never downloads filter rules. `WKContentRuleListStore` compiles each
versioned JSON shard once on device and reuses the stored result afterward.
Context deliberately does not display a blocked-request count because WebKit
does not expose an authoritative per-request callback for content rules.
