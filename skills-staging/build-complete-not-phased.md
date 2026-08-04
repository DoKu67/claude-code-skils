---
id: build-complete-not-phased
target: mvp
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** When a full scope has been designed and the user has endorsed it, build all of it.
Do not offer a reduced first phase unless cost, risk or unresolved uncertainty argues for
one — and say which if you do.

**Prediction:** If this fires, the user stops having to say "let's also do the rest."
**Falsified if:** the user asks to cut scope, or a full build produces work they did not
want.

**Occurrences**
- 2026-08-03 · session 6a888c37 · correction · offered "core four first (recommended)",
  user selected it and then immediately overrode: "These other skills look fantastic btw,
  let's also be sure to make those too"

**Open question at 1 occurrence:** this may be specific to a moment when the design was
already agreed and cheap to execute, rather than a standing preference. That ambiguity is
what the threshold is for — do not promote on a second instance that also happens to be
cheap and pre-agreed.

**Deferred by the user, 2026-08-03:** "I think it's fine if we don't build that now. I want
to get more experience with `/mvp`." Not rejected — held open deliberately until there is
enough lived experience with `mvp`'s phasing to judge whether the rule is right. Do not
propose this again until the user has run `mvp` on real work.
