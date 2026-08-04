# Staging ledger

Candidate rules and budding skills. Nothing here is loaded by any session — promotion into
`~/.claude/skills/` is the only way a candidate takes effect.

Written by [`reflect`](../skills/reflect/SKILL.md), promoted by
[`codify`](../skills/codify/SKILL.md), swept by
[`skill-audit`](../skills/skill-audit/SKILL.md). The candidate file format lives in
`codify`.

**This directory is a queue, not an archive.** A promoted candidate's file is deleted and
its provenance — occurrences, verbatim quotes, session ids — lives in the promotion commit.
Rejected candidates keep their file forever, so the same idea is never re-proposed.

## Pending

| candidate | target | occ / threshold | signal | status | last seen |
|---|---|---|---|---|---|
| [load-companion-skill-at-its-trigger](load-companion-skill-at-its-trigger.md) | `tune-loop` | 2 / 3 | correction | staged | 2026-08-03 |
| [name-the-path-of-written-records](name-the-path-of-written-records.md) | `notes` | 2 / 3 | correction | staged | 2026-08-03 |
| [build-complete-not-phased](build-complete-not-phased.md) | `mvp` | 1 / 3 | correction | staged — **deferred** pending `mvp` experience | 2026-08-03 |

## Promoted

History only — the files are gone, the rules live in the skills below, and `git log
--grep=codify:` has the evidence.

| candidate | became | promoted | note |
|---|---|---|---|
| commit-at-checkpoints | [`checkpoint-commits`](../skills/checkpoint-commits/SKILL.md) | 2026-08-03 | below threshold on direct instruction; overrides a harness default |
| consistency | [`consistency`](../skills/consistency/SKILL.md) | 2026-08-03 | direct request |
| prior-work | [`prior-work`](../skills/prior-work/SKILL.md) | 2026-08-03 | direct request; first live use of its own method |
| show-the-concrete-artifact | [`codify`](../skills/codify/SKILL.md) | 2026-08-03 | direct request |
| codify-direct-request-threshold | [`codify`](../skills/codify/SKILL.md) | 2026-08-03 | **meta-edit** — changed a threshold in `codify` itself |
| scaffold-env-and-tests | [`mvp`](../skills/mvp/SKILL.md) | 2026-08-03 | below threshold on direct instruction |

**Status:** `staged` accumulating · `rejected` kept with its reason so it is never
re-proposed · `superseded` replaced by a later rule.
