---
id: codify-direct-request-threshold
target: codify
kind: meta
signal: direct-request
status: promoted
occurrences: 1
threshold: 1
promoted: 2026-08-03
promoted_to: skills/codify/SKILL.md
---

**Rule:** A rule the user asks for directly, in their own words, promotes at 1 occurrence.
Thresholds gate inference, not instruction.

**Prediction:** If this fires, a direct "make that a rule" is never met with "let's wait for
it to recur."
**Falsified if:** rules promoted this way turn out to need revision more often than rules
that waited for their threshold.

**Occurrences**
- 2026-08-03 · session 6a888c37 · direct request · "yes, add the direct request row to codify"

**Why this is a privileged edit:** it changes a promotion threshold in `codify` itself —
one of the three constraints that may never move by inference. It moved because the user
named the file and the row explicitly, which is the only path the rule allows.

**What it does not change:** the approval step, the signal-source boundary in `reflect`, the
rejection record, or any threshold for an *inferred* candidate. A direct request still gets
a shown diff and still requires a yes. Discovered while promoting
[scaffold-env-and-tests](scaffold-env-and-tests.md), which had to go in below its threshold
for exactly this reason.
