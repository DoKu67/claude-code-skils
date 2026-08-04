---
id: cut-what-is-not-buying-much
target: mvp
kind: rule
signal: correction
status: staged
occurrences: 2
threshold: 3
---

**Rule:** When a file, section or abstraction is not clearly earning its place, propose
deleting it rather than maintaining it. Say what it would cost to lose and let the user
decide — the default answer to "should this exist" is no.

**Prediction:** If this fires, the user stops having to point at structures and say they are
not worth their weight.
**Falsified if:** something deleted has to be rebuilt, or the user asks for more structure
rather than less.

**Occurrences**
- 2026-08-03 · session bb7423c8 · correction · "Let's just get rid of @journal/notes.md and
  put all that information into @journal/experiments.md I don't think we're buying much also
  get rid of @journal/notes.md after you update this" — I had already documented the overlap
  in an `/explain` pass (two of four entries duplicated `experiments.md`, and "what's next"
  living in three places that had diverged to 5 items vs 7) and proposed *resolving* the
  boundary rather than removing the file.
- 2026-08-03 · session bb7423c8 · correction · "yes apply it however still keep it readable
  in 30 seconds" — I had proposed a seven-row table for `tldr` while noting in the same
  message that it might be too much; the constraint had to come back from the user rather
  than being applied by me.

**Note.** Related to the staged `build-complete-not-phased`, and possibly its opposite face:
that one says do not offer a reduced first build, this one says do not keep what is not
paying. They are compatible — build the whole agreed scope, then cut what turns out not to
earn its place — but if a third occurrence of either arrives, check whether one wording
covers both before promoting two rules.

**Counter-instance, 2026-08-04 · session 33c950a9 — does NOT increment the count.** Asked
what to do about `tune-report`, which duplicates four of its five sections with
`journal/experiments.md` and has never fired, the user chose neither of this rule's two
options: *"don't create remport.md just don't use /tune-report at the moment / don't
deprecate it either yet, just wait to see what happens."*

Had this rule been live it would have produced the wrong action — it would have had me
propose deprecating `tune-report`, which the user explicitly declined. **Wait-and-see is a
third option the rule's binary framing does not have**, and it is the right one when the
thing costs nothing to keep and the evidence that would settle it has not arrived yet
(here: no sweep has run to completion, so nothing has ever exercised the skill).

Before promoting, the wording must carry that boundary: propose cutting what is not earning
its place **and is costing something to keep** — maintenance, ambiguity, or a reader's
attention. Something inert and unfinished is not yet a candidate for cutting.
