---
id: commit-at-checkpoints
target: new:checkpoint-commits
kind: new-skill
signal: correction
status: promoted
occurrences: 2
threshold: 3
promoted: 2026-08-03
promoted_to: skills/checkpoint-commits/SKILL.md
---

**Rule:** Commit at natural checkpoints — a component passing its gate, a run recorded, a
consistency sweep cleared — without waiting to be asked. Then ask, without blocking, whether
to keep those commits, squash a chosen set, or fold them into one.

**Promoted below threshold, and live rather than staged, on the user's direct instruction:**
"I guess why would this be this be an inert skill? Let's just make the skill and use it".
The 2/3 occurrence count was evidence for *a* rule; the user then specified the design
themselves, at which point there was no inference left to validate.

**Prediction:** If this fires, the user stops asking whether progress was saved.
**Falsified if:** the user asks for fewer commits, or objects to work landing before review.

**Occurrences**
- 2026-08-03 · session 01PqXfrt · correction · "did you make a commit to save our progress?
  please do so" — asked after ~3 hours of work across 25 files, none of it committed.
- 2026-08-03 · session 01PqXfrt · explicit · "fund the line search, measure noise floor
  after. Be sure to commit your changes too" — second reminder in the same session,
  appended to an unrelated instruction.

**Design settled by the user**, answering the four open questions:
1. Option 3 is a rolling single commit that later checkpoints append to; `reset --soft` is
   the safe mechanism — "nothing leaves disk".
2. `rebase -i` was what they had in mind; told it is unavailable in this harness, they said
   "the mechanism is more important than the method". `reset --soft` + re-commit stands in.
3. "Once a commit is pushed don't touch it."
4. Cadence: natural pauses, plus when the checkpoint count gets large. "One commit per large
   task in a todo is a good heuristic."

**The constraint the user stated twice, in caps:** "NEVER NEVER for this skill get rid of
work/revert commits! this is more for just 'when should we commit' sort of thing." Written
into the skill as its own section with an explicit forbidden-command table.

**Note on the harness default.** The session instructions say "Commit or push only when the
user asks." This skill overrides that, on the user's direct instruction to build and use it.
