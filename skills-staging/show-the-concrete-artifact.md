---
id: show-the-concrete-artifact
target: codify
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** When proposing an action described in the vocabulary of a system you just built,
show the concrete artifact it produces — the file, the diff, the row — before asking for a
decision on it.

**Prediction:** If this fires, proposals are answered with a yes or a no rather than with
"what does this entail?"
**Falsified if:** the user asks for less detail in proposals.

**Occurrences**
- 2026-08-03 · session 6a888c37 · correction · "What do you mean staging the conda/pytest
  scaffolding rule? what does this entail" — after which showing the candidate file and the
  `mvp` diff produced an immediate "yes promote it now"

**Note:** medium confidence at 1 occurrence. It is inferred from a clarifying question
rather than stated, and the evidence is one before/after within a single exchange.
