---
id: commit-after-run-not-firing
target: checkpoint-commits
kind: trigger
signal: explicit
status: staged
occurrences: 2
threshold: 3
---

**This is a trigger problem, not a new rule.** `checkpoint-commits` already lists *"a run
finished and its result was recorded"* as a commit moment. The user still had to ask for it.

**Rule (as a trigger fix):** `checkpoint-commits` fires reliably on a todo list with large
tasks, and unreliably inside a long autonomous loop where the checkpoints are *runs* rather
than *tasks*. Its description names "a tuning loop recording runs" — so the words are there
and the moment still passed. The candidate fix is a pointer from
[`tune-loop`](../skills/tune-loop/SKILL.md) step 6: the entry's closing conditions already
include *"The work is committed"* as condition 7, which means the rule exists in two skills
and fired in neither.

Before promoting, diagnose which of the two it is: a trigger that does not match the
autonomous-loop context, or a closing condition that is read as advisory. **Do not reword
both** — the last trigger candidate against `tune-loop`
([`load-companion-skill-at-its-trigger`](load-companion-skill-at-its-trigger.md)) was
rejected precisely because it fitted a "skill did not load" diagnosis to a failure that was
actually a check being run and ignored. The same shape may be at work here.

**Prediction:** If this fires, a long unattended session leaves one commit per experiment
without the user asking.
**Falsified if:** the commits were actually happening and the user wanted something else —
a different granularity, or the metric in the subject line — in which case this is a
formatting preference and not a trigger problem at all.

**Occurrences**
- 2026-08-04 · session 1baba5b8 · explicit · *"please commit after every experiment is ran"*
  — said while setting up an unattended overnight tuning session, after four completed runs
  had been committed in two batches rather than one commit each.
- 2026-08-04 · session 1baba5b8 · correction · *"can you please update all documents and
  commit for this latest run?"* — said **after** the rule above had been given and accepted.
  Block 2's result, the main finding of the overnight session, had been evaluated ~1 h
  earlier and sat with neither its journal entry nor its commit. The instruction had been
  received, acknowledged, and still did not fire on the next run that completed, which is
  what makes this a trigger problem rather than a missing rule.
