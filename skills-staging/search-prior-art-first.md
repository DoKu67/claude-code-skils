---
id: search-prior-art-first
target: mvp
kind: rule
signal: explicit
status: staged
occurrences: 1
threshold: 3
---

**Rule:** Before designing something new, search for how it has already been solved. Report
what converges across implementations and where they consistently fall short — the gaps are
usually the design.

**Prediction:** If this fires, the user never has to ask "search the internet, I'm not the
first one to do this."
**Falsified if:** the user asks to skip the search, or the searches stop changing the
design.

**Occurrences**
- 2026-08-03 · session 6a888c37 · explicit · "Please also search the internet for how other
  people have done this since i'm not the first one to do this"

**Note:** the tell is that the user had to ask. The default behaviour was to design from
first principles, and the search materially changed the result — the 1-2-3 codification
rule, delta-not-rewrite, and the entire pruning layer came from prior art, and the four gaps
those implementations share became the design's distinguishing features.
