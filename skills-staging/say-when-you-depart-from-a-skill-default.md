---
id: say-when-you-depart-from-a-skill-default
target: coding-standards
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** When you set a value a loaded skill shows differently — its example config, its
stated default, its recommended shape — say so at the time and give the reason. A silent
departure from a skill's own example is indistinguishable from not having read it.

**Prediction:** If this fires, the user never has to ask "did you follow /<skill>?" because
every departure was announced when it was made.
**Falsified if:** the announcements become noise — a departure named on every trivial value —
or the user says they do not want to hear about them.

**Occurrences**
- 2026-08-03 · session bb7423c8 · correction · "hi, we have an issue, I don't see the current
  run on my wandb ... did you follow /ml_logging" — `ml_logging`'s example config shows
  `wandb_mode: online`; I wrote `offline` without saying so. Its degradation path is
  online → offline *on an init failure*, so I had hardcoded the fallback as the starting
  point and no run ever reached the dashboard. Compounded by `wandb_entity: null`, which
  resolved to a different entity than the one being watched. Both silent, both mine, and the
  loss was noticed hours later.

**Why `coding-standards` and not the individual skills.** The failure is not specific to
`ml_logging`; it is the general shape of taking a skill's example as a template and changing
one value without flagging it. `coding-standards` already governs "where a Should-fix rule
loses to something local, say so when the work is reviewed" — this is the same obligation
pointed at a skill's defaults rather than at its rules.
