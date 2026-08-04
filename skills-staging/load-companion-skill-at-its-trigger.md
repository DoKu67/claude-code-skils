---
id: load-companion-skill-at-its-trigger
target: tune-loop
kind: trigger
signal: correction
status: staged
occurrences: 2
threshold: 3
---

**Threshold raised 1 → 3 by the user, 2026-08-03**, along with every non-direct-request
candidate. Not ready. The third occurrence is also the test the note at the bottom of this
file asks for: if it lands against a skill whose description is already unambiguous, the
defect is not in any description and this should be reconsidered rather than promoted.

**Rule:** When a loaded skill names a companion and the moment it fires — "after every
launch", "before reporting a multi-file change as done" — load the companion at that
moment. Do not substitute your own reading of the situation for the companion's checklist,
however unambiguous the signals look.

**Prediction:** If this fires, `run-triage` is loaded at step 5 of every tuning iteration and
`consistency` before every multi-file change is reported done, rather than after the user
notices they were skipped.
**Falsified if:** loading the companion is repeatedly redundant — it returns the same verdict
the inline judgement already reached, across several launches — or the reload cost visibly
slows the loop without changing an outcome.

**Occurrences**
- 2026-08-03 · session 01PqXfrt · correction · "are you aware of the skills I just made in
  the past hour, there are some for specifically finetuning rlvr. please list relevant
  skills to this project and if you're using them" — `tune-loop` was loaded and names
  `run-triage` at step 5 ("after every launch"); triage was instead done ad hoc twice. The
  checklist, once loaded, immediately caught an entropy decline of −33.7% that the inline
  pass had recorded as "mild" at step 15.
- 2026-08-03 · session 01PqXfrt · correction · "/consistency" — invoked by the user after
  several multi-file changes had already been reported as done. `consistency`'s own
  description says "Run it before reporting a multi-file change as done." The sweep found a
  config default still set to a learning rate the project had already documented as wrong,
  and a `PLAN.md` budget claim wrong by 48%.

- 2026-08-03 · session 01PqXfrt · correction · "please apply this to the current files in
  @journal/" — the provenance backfill had been reported as done and committed while
  `experiments.md` was untouched. `consistency` was not run before reporting, for the third
  time. Worse: the audit script I *did* run printed `experiments.md: 3 entries, 0 provenance
  markers` and I committed past it.

**Threshold reached — 3/3 — and its own falsification test fires with it.**

The note below asked what a third occurrence would mean if it landed against a skill whose
description is already unambiguous. It has. `consistency`'s description says, in its own
words, *"Run it before reporting a multi-file change as done."* There is no wording that
makes that clearer, so **the defect is not in any description and this must not be promoted
as a description edit.**

What the three occurrences actually share is not a vague trigger. It is that the companion
was skipped at the exact moment its own output would have been inconvenient — mid-run when
triage would have slowed a launch, and at report time when a sweep would have delayed a
"done". The third occurrence sharpens it further: the check was not merely skipped, it was
*run and its output not read*. A rule that says "load the companion" would not have caught
that; the audit was loaded and printed the answer.

**Recommendation: reconsider, do not promote.** Either reword this candidate as a rule about
acting on verification output rather than loading skills, or reject it and let the three
occurrences stand as evidence for whatever replaces it. That is the user's call.

**Original note on target, kept.** Staged against `tune-loop` because that is where the
pointer is most explicit (step 5, "Triage — `run-triage`, early"). The second occurrence is
`consistency`, whose description is already clear about its trigger — so if the fix is a
description edit, `tune-loop` is the place; if the pattern recurs against skills whose
descriptions are already unambiguous, the defect is not in any description and this candidate
should be reconsidered rather than promoted again.
