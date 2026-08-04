---
name: skill-audit
description: Prune and repair the skill set — find rules that never fire, rules that contradict each other, skills that have outgrown their own trigger, and staged candidates that have gone stale. Use when the user runs /skill-audit, when a skill passes its size cap, when a codified rule keeps getting violated, when two skills seem to disagree, on a periodic sweep, and whenever the skill set feels like it is getting in the way rather than helping.
---

# skill-audit

Every system like this accumulates. Almost none of them subtract, and that is what turns a
skill set from an asset into a tax: stale rules mislead confidently, a bloated skill dilutes
its own trigger until it stops loading when needed, and contradictory rules make the whole
set feel arbitrary.

**This skill is the subtraction pass.** Like stage 2.5 of [`mvp`](../mvp/SKILL.md), it adds
nothing. If the audit's diff introduces a new rule, that rule belongs in staging and goes
through [`codify`](../codify/SKILL.md) like anything else.

Run it when a cap trips, when something feels wrong, or periodically. It ends in a proposed
diff the user approves — the audit does not silently delete anything.

---

## The first question: wrong rule, or wrong trigger?

When a codified rule keeps getting violated, there are two entirely different diagnoses and
they have opposite fixes. Getting this backwards is the most expensive mistake available
here, because rewriting the body of a skill that never loaded produces no change and burns
the belief that the system works.

| | Wrong trigger | Wrong rule |
|---|---|---|
| **Tell** | The skill was never loaded in the sessions where the rule was violated | The skill loaded, and the rule was followed — and the outcome was wrong or unwanted |
| **Cause** | The `description` does not name the situation, or overlaps another skill that won it | The rule is stale, too broad, or was inferred from too few occurrences |
| **Fix** | Edit the **description**: name the trigger words, the situations, the tools involved | Narrow the rule, add its exception, or retire it |
| **Wrong fix** | Rewriting the body — nothing read it | Rewriting the description — it fired fine |

**Check load history before touching a body.** If the rule was violated in five sessions and
the skill loaded in none of them, the body is not the problem and no edit to it will help.

This is the same distinction [`run-triage`](../run-triage/SKILL.md) draws between a bad
hyperparameter and a bug: one is fixed by changing a value, and the other is not fixed by
any value.

---

## What the audit looks for

| Finding | How you spot it | Default action |
|---|---|---|
| **Never fired** | Codified 90+ days ago; no session has referenced or needed it | Retire — it lives in git history |
| **Repeatedly violated** | The same correction keeps recurring after codification | Diagnose per the table above |
| **Contradiction** | Two rules cannot both be followed | Newest wins. Supersede the older explicitly, naming the newer |
| **Duplication** | The same rule in two skills, worded differently | Keep it in the skill that owns the job; delete the other and link |
| **Drifted into a fact** | A rule naming a library version, a model id, a path | Rewrite as a process rule, or retire it — content rules go stale silently |
| **Over cap** | A skill past ~200 lines or ~12 rules | Split, or cut the weakest rules. **Hitting the cap triggers an audit, never an append** |
| **Diluted description** | The description has grown to cover several jobs | Split the skill; each half gets a sharp trigger |
| **Stale candidate** | Staged 90+ days at 1 occurrence | Reject with reason "did not recur" — kept, not deleted |
| **Single-project rule** | A global rule that only ever applies to one repo | Move to that repo's `CLAUDE.md` |

### Contradictions get superseded, not deleted

A skill is a contract, so it must not carry dead rules — a reader cannot tell which of two
conflicting instructions is live. Remove the old rule from the body and let the supersede
note carry one line saying what changed and when.

This differs on purpose from [`notes`](../notes/SKILL.md), where superseded reasoning stays
in place forever: a notes file is a *story* and its history is the point; a skill is a
*contract* and its history belongs in git.

---

## Caps

| Surface | Cap | On breach |
|---|---|---|
| One skill | ~200 lines, ~12 rules | Audit it — split or cut. Do not append |
| Staging | ~30 open candidates | Sweep the stale ones |
| One promotion | 20 lines | It is a budding skill, not a delta |

The caps are forcing functions rather than limits. Without one, nothing ever prunes, because
pruning is never the most urgent thing in any individual session. A cap makes the audit
arrive on a schedule set by the accumulation itself.

---

## The report

```markdown
## Skill audit — 2026-11-02 · 14 skills, 6 findings

**Retire (3)** — no evidence of use since codification
| rule | in | codified | why |
|---|---|---|---|
| "prefer pathlib over os.path" | coding-standards | 2026-07-14 | never referenced; also a content rule |

**Repeatedly violated (1)**
| rule | in | violations | diagnosis |
|---|---|---|---|
| "run tests before saying done" | mvp | 4 sessions | **trigger** — mvp loaded in 0 of 4. Fix the description, not the body |

**Contradiction (1)** — `notes` says keep superseded reasoning; `codify` says remove dead
rules. Both correct in context; neither says so. → one clarifying line in each, and it is a
*new* rule, so it goes through staging.

**Over cap (1)** — `rl-env-mvp` at 452 lines. Its reference files are already split; the
body has absorbed tuning guidance that `tune-loop` now owns. Proposed cut: 60 lines.

**No action:** 8 skills unchanged.
```

Findings are proposals. The user approves the diff, and each accepted change is a commit
naming what it removed.

---

## Recursion, and its limit

This skill audits skills, and it is a skill. That is deliberate — the loop that improves the
work should be improvable by the same evidence.

It is also where a self-improving system goes wrong, so the limit is fixed: **the audit may
never weaken an approval requirement, a threshold, a signal-source boundary, or a rejection
record in `reflect`, `codify` or itself.** Those change only when the user asks directly, in
their own words. See the privileged-edit rule in [`codify`](../codify/SKILL.md).

An audit that can retire its own constraints will eventually find a reason to, and every
promotion after that inherits the doubt.

---

## Out of scope

Finding new rules — [`reflect`](../reflect/SKILL.md). Promoting anything —
[`codify`](../codify/SKILL.md). Judging whether a skill's *content* is correct on its
merits: this audit checks whether rules are live, consistent, findable and used, not whether
a technical claim inside one is true.

---

## Done when

Every finding names the evidence it came from; every repeatedly-violated rule was diagnosed
as trigger or content **before** anything was edited; contradictions are resolved with an
explicit supersede rather than two live rules; retired rules left the body and live in git;
nothing was deleted without approval; no new rule was introduced by the audit itself; and
the constraints in `reflect`, `codify` and `skill-audit` are exactly as strict as they were
before it ran.
