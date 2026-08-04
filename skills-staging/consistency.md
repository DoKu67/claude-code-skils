---
id: consistency
target: new:consistency
kind: new-skill
signal: direct-request
status: promoted
occurrences: 1
threshold: 1
promoted: 2026-08-03
promoted_to: skills/consistency/SKILL.md
---

**Rule:** After a change that ripples across files — rename, signature or default change,
swapped method, documentation update — sweep for everything that still describes the old
world, working from the diff rather than from memory.

**Prediction:** If this fires, a multi-file change is never reported as done while a doc,
test name, config string or comment still names the old behaviour.
**Falsified if:** the sweep repeatedly finds nothing on real changes, or its cost outweighs
what it catches.

**Occurrences**
- 2026-08-03 · session 6a888c37 · direct request · "I want a skill s.t. everytime that claude
  makes edits to my codebase across files etc. that it double checks that things are
  consistent across the files ... documentation ... search and replace for a variable name
  ... we change what method we're using for something"

**Prior art applied** ([`prior-work`](../skills/prior-work/SKILL.md)'s first live use).
Convergence: everyone greps for the old token afterwards and expects zero; AST tools do it
semantically; doc-drift tools pair doc blocks to code anchors. Three shared gaps became the
design — grep catches only the literal token and not the prose paraphrase, nothing sweeps
the inverse direction, and agent-specific context eviction means a sweep built from memory
checks exactly the files least likely to have been missed. Hence: **work from `git diff`,
never from recall.**

**Named `consistency`** from the user's own two candidates (`consistency`,
`check-consistency`); the shorter noun matches `notes`, `explain`, `tldr`.
