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
| [cut-what-is-not-buying-much](cut-what-is-not-buying-much.md) | `mvp` | 2 / 3 | correction | staged | 2026-08-03 |
| [say-when-you-depart-from-a-skill-default](say-when-you-depart-from-a-skill-default.md) | `coding-standards` | 1 / 3 | correction | staged | 2026-08-03 |
| [load-companion-skill-at-its-trigger](load-companion-skill-at-its-trigger.md) | `tune-loop` | 3 / 3 | correction | **REJECTED 2026-08-03** — reached threshold and falsified itself; the defect was a check run and ignored, not a skill unloaded. Kept so it is never re-proposed | 2026-08-03 |
| [name-the-path-of-written-records](name-the-path-of-written-records.md) | `notes` | 2 / 3 | correction | staged | 2026-08-03 |
| [build-complete-not-phased](build-complete-not-phased.md) | `mvp` | 1 / 3 | correction | staged — **deferred** pending `mvp` experience | 2026-08-03 |
| [orphan-skill-finding](orphan-skill-finding.md) | `skill-audit` | 1 / 1 | explicit | **ready to promote** — direct request | 2026-08-04 |

## Promoted

History only — the files are gone, the rules live in the skills below, and `git log
--grep=codify:` has the evidence.

| candidate | became | promoted | note |
|---|---|---|---|
| tldr-reads-the-state | [`tldr`](../skills/tldr/SKILL.md) | 2026-08-03 | direct request; the format was general, its references were not, and nothing said where state lives |
| refresh-coverage-with-every-row | [`tune-loop`](../skills/tune-loop/SKILL.md) | 2026-08-03 | below threshold (1/3) — went live as closing condition 3 of step 6 while the entry format was being written, rather than as its own promotion |
| summary-reaches-wandb | [`ml_logging`](../skills/ml_logging/SKILL.md) | 2026-08-03 | direct request; `run/status` and the headline metric were reaching disk but not the dashboard |
| wandb-mode-always-online | [`ml_logging`](../skills/ml_logging/SKILL.md) | 2026-08-03 | direct request; `offline` is the fallback, never a config choice |
| journal-path-for-experiments-md | [`ml_logging`](../skills/ml_logging/SKILL.md) + [`rl-env-mvp`](../skills/rl-env-mvp/SKILL.md) | 2026-08-03 | direct request; the two skills disagreed on where the run log lives |
| commit-at-checkpoints | [`checkpoint-commits`](../skills/checkpoint-commits/SKILL.md) | 2026-08-03 | below threshold on direct instruction; overrides a harness default |
| consistency | [`consistency`](../skills/consistency/SKILL.md) | 2026-08-03 | direct request |
| prior-work | [`prior-work`](../skills/prior-work/SKILL.md) | 2026-08-03 | direct request; first live use of its own method |
| show-the-concrete-artifact | [`codify`](../skills/codify/SKILL.md) | 2026-08-03 | direct request |
| codify-direct-request-threshold | [`codify`](../skills/codify/SKILL.md) | 2026-08-03 | **meta-edit** — changed a threshold in `codify` itself |
| skill-line-cap-500 | [`skill-audit`](../skills/skill-audit/SKILL.md) | 2026-08-04 | **meta-edit** — loosened the line cap 200 → 500, provisional |
| sweep-consistency-at-multi-file-changes | [`mvp`](../skills/mvp/SKILL.md) + [`tune-loop`](../skills/tune-loop/SKILL.md) | 2026-08-04 | direct request; `consistency` had never fired in 83 sessions because no skill named it |
| offer-prior-work-at-stage-1 | [`mvp`](../skills/mvp/SKILL.md) | 2026-08-04 | direct request; `prior-work` had never fired for the same reason |
| new-skill-needs-an-inbound-caller | [`codify`](../skills/codify/SKILL.md) | 2026-08-04 | **privileged edit**, tightening; a new skill's callers must now be *asked for*, not inferred |
| scaffold-env-and-tests | [`mvp`](../skills/mvp/SKILL.md) | 2026-08-03 | below threshold on direct instruction |
| explain-covers-non-code-subjects | [`explain`](../skills/explain/SKILL.md) | 2026-08-04 | direct request; a separate `question` skill failed codify's description test — same triggers as `explain`, so nothing would disambiguate them |
| explain-does-not-change-the-plan | [`explain`](../skills/explain/SKILL.md) | 2026-08-04 | direct request; `explain` forbade edits but said nothing about an in-flight todo list |

**Status:** `staged` accumulating · `rejected` kept with its reason so it is never
re-proposed · `superseded` replaced by a later rule.
