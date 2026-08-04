---
id: launch-before-writing-up
target: tune-loop
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** In an unattended loop, **launch the next run before writing up the last one.** The
accelerator is the scarce resource and the write-up is not on its critical path; a queue with
a prediction already written can start while the previous entry is still being composed.

This does not weaken step 6's *"Record — immediately, not at end of day"*. Both hold, in
this order: **launch, then record, then commit.** The failure it prevents is the loop
stalling silently — the user seeing an idle GPU while the assistant is busy being diligent
about the journal.

State the ordering explicitly, because the two rules pull against each other and the obvious
reading of "record immediately" is to record *first*.

**Prediction:** If this fires, an overnight loop shows continuous accelerator use, and the
user stops having to ask whether anything is running.
**Falsified if:** launching before the read produces runs that should not have been launched
— the previous result would have changed the next experiment. Then the rule needs a carve-out
for the case where the queue's next item depends on the result just produced, which is
common enough that it may swallow the rule.

**Occurrences**
- 2026-08-04 · session 1baba5b8 · correction · *"what's the status? I don't see anything
  running on gpu"* — the GPU had been idle while the previous experiment's entry was written
  and committed. The next experiment was already queued with its prediction and could have
  been launched first.
