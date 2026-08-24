# Content rule artifacts

Run:

```sh
scripts/compile-content-rules.swift \
  third-party/easylist/easylist.txt \
  third-party/easylist/easyprivacy.txt \
  app/Resources/ContentRules
```

The converter emits deterministic WebKit JSON from the two checked-in source
lists. Each shard stays at or below 40,000 rules, comfortably below WebKit's
per-list ceiling. Exception rules are repeated at the end of each source
shard so `ignore-previous-rules` applies within the list that contains its
blocking rules.

To download current upstream lists and regenerate the artifacts in one step,
run `scripts/update-content-rules.sh`. Review the source metadata and generated
diff before committing. Context never updates rules inside the installed app;
new rules ship only in a reviewed app release.

The app never downloads filter rules. `WKContentRuleListStore` compiles each
versioned JSON shard once on device and reuses the stored result afterward.
Context deliberately does not display a blocked-request count because WebKit
does not expose an authoritative per-request callback for content rules.
