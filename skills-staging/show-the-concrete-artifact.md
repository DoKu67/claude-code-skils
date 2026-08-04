---
id: show-the-concrete-artifact
target: codify
kind: rule
signal: correction
status: promoted
occurrences: 1
threshold: 1
promoted: 2026-08-03
promoted_to: skills/codify/SKILL.md
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

- 2026-08-03 · session 6a888c37 · direct request · "sure show-the-concrete-artifact is good"

**Note:** the rule itself was inferred from a clarifying question rather than stated, and
the supporting evidence is one before/after inside a single exchange. It promoted at 1
because the user approved it directly, which is instruction rather than inference — but the
inference behind the *wording* is still only one occurrence deep, so reword it freely if it
reads wrong in practice.
