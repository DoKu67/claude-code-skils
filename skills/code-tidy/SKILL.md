---
name: code-tidy
description: Declutter code that's grown messy or bloated after a writing session — remove dead/antiquated code, strip comments and docstrings down to what earns its place, and cut unnecessary abstraction — by running coding-standards (the house-rules lens), simplify (the actual cleanup pass), code-proof (scoped only to cuts whose safety isn't self-evident), and consistency (sweeping for what the cleanup itself should have touched and didn't) in sequence. Use when the user says "clean this up", "this feels bloated", "get rid of dead code", "tidy this up", after a large or multi-file coding session before calling it done, or whenever code you just wrote reads as messier or more complicated than the problem warranted.
---

# code-tidy

Code that's wrong is usually visible in review. Code that's just *too much* — a branch kept
"just in case," a docstring copied from somewhere and never trimmed, a wrapper built for a
generality that never arrived — passes review fine, every time, one line at a time. The mess
is only visible in aggregate, after the pressure to ship is gone. This skill is that second
pass: run once the problem is solved, asking only whether every line still earns its place.

**This doesn't invent a fifth technique.** Everything below is already covered by four
existing skills; this one's job is sequencing them correctly, scoping each to what it's
actually good at, and not letting anything fall in the gap between them.

---

## The four stages

| Stage | Skill | Role here | Runs |
|---|---|---|---|
| 1 | [`coding-standards`](../coding-standards/SKILL.md) | Load the house rules first — every call below is made against this repo's actual standard, not taste | Always, as a lens — no separate output |
| 2 | `simplify` (built-in) | The decluttering itself — dead code, comments/docstrings, bloat | Always, the main pass |
| 3 | [`code-proof`](../code-proof/SKILL.md) | Prove a risky cut didn't change behavior | Only for cuts whose safety isn't self-evident |
| 4 | [`consistency`](../consistency/SKILL.md) | Sweep for what the cleanup itself should have touched and didn't | Always, last — it needs 2 and 3's diff to sweep |

Run them in this order.

---

## Stage 1 — Standards as a lens, not a step

Invoke [`coding-standards`](../coding-standards/SKILL.md) before touching anything, and carry
its rules through stages 2–4. It produces no report here; it sets what "clean" means in this
repo, so a judgment call in stage 2 — "is this abstraction earning its place?" — is answered
against a written rule, not a preference.

---

## Stage 2 — Simplify, scoped to three things

The actual cleanup. Invoke `simplify`, steered at exactly the three complaints that motivate
this skill — not a general refactor:

| Target | What to look for | What "done" looks like |
|---|---|---|
| **Dead / antiquated code** | Unused functions, unreachable branches, commented-out blocks, unused imports/variables, a feature flag whose value has been fixed for months, a fallback for a code path that no longer exists | Deleted outright — not commented out, not moved to an `_old` file. Git history is the record, not a graveyard in the source tree |
| **Comments & docstrings** | A comment that restates what the code already says, a multi-paragraph docstring for a one-line function, a stale comment describing behavior that changed since it was written | Deleted if it doesn't explain a non-obvious WHY; trimmed to one line if it does. Never rewritten to sound better — cut or kept, no middle option |
| **Bloat / over-abstraction** | A wrapper class with exactly one implementation, a config option nobody has ever flipped, an interface built for a second case that never arrived, three similar lines turned into a generic helper used once | Collapsed to the concrete version. The test: would a first-time reader need the abstraction to understand what's happening, or only to admire it |

**Nothing here changes behavior.** If a "cleanup" would change what the code does, that's a
different task — flag it and stop, don't fold it into this pass.

---

## Stage 3 — Prove the cuts that aren't obviously safe

Most stage-2 deletions are self-evidently safe — an unused private function with zero call
sites doesn't need a proof, and running one anyway is exactly the "invented rigor"
`code-proof` itself warns against. **Reach for
[`code-proof`](../code-proof/SKILL.md) only when a cut's safety depends on reasoning, not
grep:**

- A branch or guard that looks unreachable, but the reachability argument isn't a one-line
  grep — it depends on what callers actually pass.
- Two code paths collapsed into one, on the claim that they were always equivalent.
- A check or fallback removed because "this case can't happen" — exactly the kind of claim
  that deserves either a proof or a `git blame` to find out why it was added.

For each one, state the claim as **"the simplified code behaves identically to the original
for every reachable input"** (or a narrower claim, if only part of the behavior is in
question), and prove it with `code-proof`'s **reduction-to-reference** technique, using the
pre-cleanup version as the trusted reference. A cut that fails this proof is reverted, not
shipped with a caveat.

Skip this stage entirely for a pass that only touched comments, docstrings, and genuinely
unused code — running it there would be ceremony, not verification.

---

## Stage 4 — Sweep the wake

Deleting or renaming things in stages 2–3 leaves a trail: a doc still mentioning a removed
function, a test importing something that no longer exists, a README describing a flag
that's gone. Invoke [`consistency`](../consistency/SKILL.md) against this pass's whole diff
before calling it done — this is exactly the "change touching more than one file" trigger
that skill already fires on.

---

## Before you start

**Make sure the baseline is clean and committed first.** A decluttering pass is easiest to
trust as a diff against something stable — check `git status` and commit or stash anything
already in flight before starting, so every deletion is reviewable and reversible. See
[`checkpoint-commits`](../checkpoint-commits/SKILL.md) if the pass itself will span more than
one sitting.

---

## Rules

- **Never fold in a behavior change.** If a cut, a rename, or a "simplification" would change
  what the code does — not just how it reads — that's out of scope here; name it separately
  and get it agreed to on its own.
- **Delete, don't relocate.** Commenting out, moving to a `deprecated/` folder, or renaming to
  `_unused_foo` are all still bloat — just moved. Git history is where old code lives.
- **A comment survives only by explaining a non-obvious WHY.** Anything explaining WHAT the
  code does is redundant with the code itself and gets cut.
- **Stage 3 is invoked per cut, not once for the whole diff.** A single proof covering "all
  of today's changes" isn't checkable; one claim, one proof, per risky cut.
- **This skill doesn't hunt for bugs or security issues.** That's `code-review` and
  `security-review`'s job respectively — this pass is about size and cleanliness, not
  correctness of intent or safety.

---

## Out of scope

**Finding bugs.** `code-review`'s job — this skill assumes the code already works and only
asks whether it's bigger or messier than it needs to be.

**Security issues.** `security-review`'s job, not this one.

**Fresh-build simplicity.** [`mvp`](../mvp/SKILL.md) already has a "strip it to something a
human can read" stage for code being written for the first time. This skill is for code that
already exists and has drifted — a file, a module, or a session's output that's grown messy
over time — not the first pass of a new build.

**Deciding whether a "cut" is actually a redesign.** If cleanup turns up something that needs
a real behavior change or a new abstraction to fix properly, that's a finding to raise with
the user, not something to fold into this pass silently.

---

## Done when

Stage 1's rules were loaded and applied as the standard for every call in stages 2–4; every
deletion in stage 2 is an actual deletion, not a relocation or a comment-out; every surviving
comment or docstring explains a non-obvious WHY, not the WHAT; every abstraction still
standing has a second real use, not a hypothetical one; every cut whose safety wasn't
self-evident from inspection went through a `code-proof` reduction-to-reference proof and
passed, or was reverted; `consistency` ran against the full diff and found no stale reference
to anything this pass removed or renamed; and nothing in the diff changes what the code does
— only how much of it there is.
