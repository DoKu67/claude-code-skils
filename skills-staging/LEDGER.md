# Staging ledger

Candidate rules and budding skills, newest first. Nothing here is loaded by any session —
promotion into `~/.claude/skills/` is the only way a candidate takes effect.

Written by [`reflect`](../skills/reflect/SKILL.md), promoted by
[`codify`](../skills/codify/SKILL.md), swept by
[`skill-audit`](../skills/skill-audit/SKILL.md). The candidate file format lives in
`codify`.

| candidate | target | occ / threshold | signal | status | last seen |
|---|---|---|---|---|---|
| [load-companion-skill-at-its-trigger](load-companion-skill-at-its-trigger.md) | `tune-loop` | **2 / 1** | correction | staged — **ready** | 2026-08-03 |
| [name-the-path-of-written-records](name-the-path-of-written-records.md) | `notes` | 2 / 3 | correction | staged | 2026-08-03 |
| [commit-at-checkpoints](commit-at-checkpoints.md) | `mvp` | 2 / 3 | correction | staged — **conflicts with a harness default** | 2026-08-03 |
| [consistency](consistency.md) | **new skill** | 1 / 1 | direct request | **promoted** 2026-08-03 | 2026-08-03 |
| [prior-work](prior-work.md) | **new skill** | 1 / 1 | explicit + direct request | **promoted** 2026-08-03 | 2026-08-03 |
| [build-complete-not-phased](build-complete-not-phased.md) | `mvp` | 1 / 3 | correction | staged — **deferred** pending `mvp` experience | 2026-08-03 |
| [show-the-concrete-artifact](show-the-concrete-artifact.md) | `codify` | 1 / 1 | direct request | **promoted** 2026-08-03 | 2026-08-03 |
| [codify-direct-request-threshold](codify-direct-request-threshold.md) | `codify` **(meta)** | 1 / 1 | direct request | **promoted** 2026-08-03 | 2026-08-03 |
| [scaffold-env-and-tests](scaffold-env-and-tests.md) | `mvp` | 1 / 2 | explicit + direct request | **promoted** 2026-08-03 | 2026-08-03 |

**Status:** `staged` accumulating · `promoted` in a skill, with date and target ·
`rejected` kept with its reason so it is never re-proposed · `superseded` replaced by a
later rule.

Rejected candidates stay in this table. A system that forgets what was rejected proposes it
again every few weeks.
