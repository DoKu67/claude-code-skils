---
id: orphan-skill-finding
target: skill-audit
kind: rule
signal: explicit
status: staged
occurrences: 1
threshold: 1
---

**Rule:** Add an **Orphan** finding to the audit: a skill with zero invocations in the
transcripts *and* zero inbound links from other skills. The fix is a pointer from the skill
that owns the moment, not a rewrite of the orphan's body.

**Prediction:** If this fires, orphaned skills are found by the audit instead of by the user
noticing months later that a skill they asked for has never run.
**Falsified if:** the count is unreliable enough to produce false orphans — a skill that did
fire but was not recorded as a `Skill` call.

**Occurrences**
- 2026-08-04 · session 33c950a9 · explicit · "there semeed to be an issue with naming skills
  directly within other skills, and that this was not being done, how can we enforce this?"

**The measurement, which already works.** Invocation counts are greppable from the
transcripts today:

```
find ~/.claude/projects -name '*.jsonl' -exec grep -oh '"skill":"[a-zA-Z_-]*"' {} + \
  | sort | uniq -c | sort -rn
```

Run during this session it returned 7 of 21 skills at zero: `checkpoint-commits`,
`consistency`, `escalate`, `prior-work`, `sft-env-mvp`, `skill-audit`, `tune-report`.

**Why this matters for the audit specifically.** `skill-audit` currently defines a
never-fired rule as "codified 90+ days ago", which is unmeasurable on a skill set that is one
day old and stays unmeasurable until November. The invocation count is the same finding
available now, and it does not depend on the calendar. Same for `stale candidate`, which has
the identical 90-day problem.

**Prior art, surveyed 2026-08-04.** Three mechanisms worth taking:

- **Sphinx** — `orphan: true` declared in the skill's own frontmatter is the exemption, so a
  skill with zero inbound links and no marker is the finding. See
  [[new-skill-needs-an-inbound-caller]].
- **Vulture** — reports dead code with a **confidence score of 60–100%** and an
  auto-generated whitelist rather than a binary verdict. Our detector needs the same: the
  static check run this session produced 9 hits, all worked examples, so a binary
  violation/clean output would have been 100% noise.
- **SEO crawlers** — an orphan cannot be found from the link graph alone; discovery requires a
  **second inventory** (sitemaps, analytics). Ours is the transcript invocation count. The
  link graph says a path exists; only the counts say anyone walked it.

**Cadence matters more than detection.** Wikipedia detects orphans perfectly well — 8.8M of
them, ~15% of all articles — and de-orphanizes at roughly **0.5% per month**. Detection
without a forcing cadence produces a backlog nobody works. So the every-10-promotions trigger
is the load-bearing part of this candidate, not the check.

**Boundary.** Zero invocations is not automatically a defect — `tune-report` has never fired
because no sweep has run to completion, which is a fair reason, and the user has explicitly
chosen to leave it unused and not deprecate it while evidence accumulates (2026-08-04). The
finding reports; it does not retire. Pairs with [[new-skill-needs-an-inbound-caller]], which
is the prevention half.
