---
id: prior-work
target: new:prior-work
kind: new-skill
signal: explicit + direct request
status: promoted
occurrences: 1
threshold: 1
promoted: 2026-08-03
promoted_to: skills/prior-work/SKILL.md
---

**Rule:** Before designing something new, survey how it has already been solved. Report what
implementations converge on and where they all fall short — the gaps are the design.

**Prediction:** If this fires, the user never has to ask "search the internet, I'm not the
first one to do this."
**Falsified if:** the user asks to skip the search, or surveys stop changing designs.

**Occurrences**
- 2026-08-03 · session 6a888c37 · explicit · "Please also search the internet for how other
  people have done this since i'm not the first one to do this"
- 2026-08-03 · session 6a888c37 · direct request · "let's do prior-work and make it a skill,
  don't make it an mvp rule, it's not related to mvp per se"

**Promoted as a skill, not an `mvp` rule.** Two reasons, the second the user's: as a bare
imperative it would be a one-rule skill, but what actually paid off was the *method* —
multi-angle search, a second round using the vocabulary the first taught, and the
convergence/gaps output shape. And it fires outside `mvp`'s trigger, since it was first
invoked for designing a skill system rather than for starting a software project.

**Renamed** from `search-prior-art-first` at the user's request. "Prior art" is standard
usage from patent law, but the jargon was not earning its place; `prior-work` says the same
thing in plainer words.

**Tell worth keeping:** the user had to ask. The default was to design from first
principles, and the search materially changed the result — the 1-2-3 codification rule,
delta-not-rewrite and the entire pruning layer came from prior art, and the four gaps those
implementations share became the design's distinguishing features.
