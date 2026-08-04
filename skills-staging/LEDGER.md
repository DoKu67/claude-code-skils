# Staging ledger

Candidate rules and budding skills, newest first. Nothing here is loaded by any session —
promotion into `~/.claude/skills/` is the only way a candidate takes effect.

Written by [`reflect`](../skills/reflect/SKILL.md), promoted by
[`codify`](../skills/codify/SKILL.md), swept by
[`skill-audit`](../skills/skill-audit/SKILL.md). The candidate file format lives in
`codify`.

| candidate | target | occ / threshold | signal | status | last seen |
|---|---|---|---|---|---|
| [search-prior-art-first](search-prior-art-first.md) | `mvp` | 1 / 3 | explicit | staged | 2026-08-03 |
| [build-complete-not-phased](build-complete-not-phased.md) | `mvp` | 1 / 3 | correction | staged | 2026-08-03 |
| [show-the-concrete-artifact](show-the-concrete-artifact.md) | `codify` | 1 / 3 | correction | staged | 2026-08-03 |
| [codify-direct-request-threshold](codify-direct-request-threshold.md) | `codify` **(meta)** | 1 / 1 | direct request | **promoted** 2026-08-03 | 2026-08-03 |
| [scaffold-env-and-tests](scaffold-env-and-tests.md) | `mvp` | 1 / 2 | explicit + direct request | **promoted** 2026-08-03 | 2026-08-03 |

**Status:** `staged` accumulating · `promoted` in a skill, with date and target ·
`rejected` kept with its reason so it is never re-proposed · `superseded` replaced by a
later rule.

Rejected candidates stay in this table. A system that forgets what was rejected proposes it
again every few weeks.
