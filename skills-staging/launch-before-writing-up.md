---
id: launch-before-writing-up
target: tune-loop
kind: trigger
signal: explicit
status: staged
occurrences: 2
threshold: 3
---

**Reclassified from `rule` to `trigger` on the second occurrence.** The rule already exists —
`tune-loop` step 6 says *"Record — immediately, not at end of day"* and closing condition 7
says *"The work is committed"*. Both were in force and neither fired. A third statement of
the same rule is not the fix.

**Rule (as a trigger fix):** name the sequence explicitly at the point a run finishes —
**launch the next run → write the entry → commit** — rather than leaving "immediately"
to be inferred. Step 6's *"immediately, not at end of day"* is read as *"not later today"*,
which a one-hour gap technically satisfies. The failure mode is an unattended loop where the
next thing to do is ambiguous and both halves get dropped: on the occurrence below the GPU
sat idle **and** the result went unwritten for the same hour, so the two rules failed
together rather than trading off.

Launching first costs seconds and keeps the accelerator busy; it must never become the
reason the write-up waits. When there is no next run to launch, the entry is written first.

**Prediction:** If this fires, an overnight loop shows continuous accelerator use *and* an
entry per run, without the user asking for either.
**Falsified if:** launching before the read produces runs that should not have been launched
— the previous result would have changed the next experiment. That case is common enough
that it may need a carve-out, or may invert the ordering entirely.

**Occurrences**
- 2026-08-04 · session 1baba5b8 · correction · *"what's the status? I don't see anything
  running on gpu"* — the GPU had been idle while the previous experiment's entry was written
  and committed.
- 2026-08-04 · session 1baba5b8 · explicit · *"make a note to always record the results of
  the last run immediately after that run finishes"* — said after Block 2's result, the main
  finding of an overnight session (70.5% vs a 30.5% baseline), sat unwritten for ~1 h until
  the user asked what had happened. **The same hour had the GPU idle**, so this is the same
  lapse as occurrence 1 seen from the other side, not a competing rule.

**Note for whoever promotes this:** it lands in the same territory as
[`commit-after-run-not-firing`](commit-after-run-not-firing.md), which is also a trigger
problem about the same closing step. Consider whether they are one candidate — *the closing
step of an experiment does not reliably fire in an autonomous loop* — rather than two. And
apply the caution recorded in
[`load-companion-skill-at-its-trigger`](load-companion-skill-at-its-trigger.md): the last
trigger candidate against `tune-loop` reached threshold and was rejected because it fitted a
"skill did not load" diagnosis to a check that had run and been ignored.
