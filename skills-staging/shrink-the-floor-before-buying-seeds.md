---
id: shrink-the-floor-before-buying-seeds
target: tune-loop
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** The noise floor is **a property of the configuration, not a fact about the
project.** When the measured floor is too wide to resolve the effects you intend to search
for, the first move is to *shrink it* — more prompts per gradient step, more steps, a lower
sampling temperature — not to buy more seeds per cell.

The current "Is the delta real" section treats the floor as something to measure and then
live with: it says what to do when seeds are too expensive, but never that the floor itself
is reducible. Both escapes it offers — spend 3x on seeds, or declare the floor unknown —
leave the search underpowered against the same wide floor.

Add the diagnostic: **problem-exposures per run = prompts per gradient step x steps.** When
that number is small, a wide floor is the expected consequence rather than a surprise, and
the fix is upstream of the search entirely.

**Prediction:** If this fires, a wide floor sends the loop to fix gradient noise before an
axis search is attempted against it, instead of after a block of cells has been spent
producing a winner that means nothing.
**Falsified if:** a project's floor turns out to be irreducible at any affordable batch or
step count, so the advice costs a wasted resize before the seeds get bought anyway.

**Occurrences**
- 2026-08-04 · session 1baba5b8 · correction · *"Why so few questions? Don't we have GPU
  memory? Can't we have larger batches?"* — three runs of an **identical** config differing
  only in `train.seed` scored **45.5% / 30.0% / 48.5%**, one of them *below* the untrained
  baseline, giving a floor of ±9.9pp against a queued learning-rate axis whose cells were
  never going to differ by that much. The loop had correctly measured the floor and correctly
  refused to call the result a win, then planned to run the axis anyway. The cause was
  **720 problem-exposures per run** (8 prompts/step x 90 steps); `tune-loop` has no
  diagnostic that would surface that number, and its own guidance points at seeds rather
  than at the batch.
