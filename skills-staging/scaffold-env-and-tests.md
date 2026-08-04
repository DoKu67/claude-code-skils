---
id: scaffold-env-and-tests
target: mvp
kind: rule
signal: explicit
status: promoted
occurrences: 1
threshold: 2
promoted: 2026-08-03
promoted_to: skills/mvp/SKILL.md
---

**Rule:** A new project's first commit includes a reproducible environment file and a
runnable test command, before the first component is built.

**Prediction:** If this fires, no project reaches its second component without the test
runner executing an empty suite green.
**Falsified if:** the user deletes the environment file, or asks to skip it on a project.

**Occurrences**
- 2026-08-03 · session 6a888c37 · explicit · "my preferred tools include conda and pytest"
- 2026-08-03 · session 6a888c37 · direct request · "yes promote it now"

**Promotion note:** promoted at 1 occurrence below the threshold of 2, because the second
entry is a **direct request** rather than an inferred signal. The threshold protects against
inference, not instruction — the gap this exposes in `codify` is open and unfixed as of
this promotion.

Tool names deliberately excluded from the delta: conda and pytest live in memory
(`tooling-preferences`), so the process rule survives a change of tooling.
