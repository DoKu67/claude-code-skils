---
name: coding-standards
description: Apply this repo's house rules while writing or changing code. Use whenever you are about to write, edit, or refactor code in this repo, and when the user corrects a design or style decision that should become a standing rule.
---

# Coding Standards

The rules live in [`CODING_STANDARDS.md`](CODING_STANDARDS.md), beside this file in `~/.claude/skills/coding-standards/` — **the single source of truth**, applying to every project. This skill governs when they get applied and how they grow. It never restates a rule; a rule stated twice drifts.

`code-review` applies these standards to a finished diff. This skill applies them *while the code is being written*, so the review has less to find.

Two reference files, reached only when their pointer fires:

- [`examples.md`](examples.md) — a violation and its fix for every rule. Read the entry for a rule before you flag it, so the finding names a shape rather than a feeling.
- [`patterns.md`](patterns.md) — candidate design patterns indexed by the friction each solves. Read only at the *locked-in* stage, and only with a friction you can already name.

One set of standards, everywhere. There is no per-repo override file, and a repo asking for one is a signal to change the global rule rather than to fork it — take that back to **Capture** below.

## Apply

Read `CODING_STANDARDS.md` before the first edit of a session, and again after any compaction.

**Establish the stage first.** Every rule is gated on whether the module is *exploring* or *locked-in*, and getting this wrong is the most expensive mistake available here: applying locked-in rules to exploratory code buries a moving design under abstractions that then have to be honoured. A module is locked-in when its interface has survived two changes without moving. When it's ambiguous, ask — and while waiting, treat it as exploring.

Tiers do not appear in your output while writing. They are a review instrument; here they are simply how much a rule binds you. Satisfy Blocking rules without comment. Where a Should-fix rule loses to something local, say so when the work is reviewed rather than in a code comment.

**The existing repo wins, until you're told otherwise.** Where a standard and an established convention in the surrounding code disagree, follow the surrounding code. A file written half in one style and half in another is worse than either style.

On the first such conflict in a repo, name it and ask which way it goes: **abide** — the repo's convention holds here and the standard yields, or **convert** — the repo moves to the standard, as its own deliberate piece of work rather than smuggled into an unrelated change. Until the user answers, follow the repo.

That answer is a decision the user makes once per repo, not one you make per file. Record it in that repo's `CLAUDE.md` so the next session doesn't re-litigate it — the standards file never changes to accommodate a single repo.

Where two rules pull against each other — duplication against premature abstraction, immutability against the cost of copying a large buffer — the doc's own exception clause settles it. If it doesn't, ask rather than picking.

**Done when:** every Blocking rule holds across the changed lines at the module's current stage, and each Should-fix rule you set aside has a stated reason.

## Capture

A correction is a rule trying to be born. When the user overrules a decision you made on style, structure, error handling, naming, or dependencies, ask whether it should become standing.

If yes, draft it in the doc's own shape — rule as an imperative, the reason, its tier, its stage if gated, and the conditions under which it doesn't apply — then add the matching violation-and-fix pair to `examples.md`. Show both before writing.

Prune while you're in there. A rule the tooling now enforces, or one describing code no longer in the repo, gets deleted rather than kept out of caution.

**Done when:** the rule is in `CODING_STANDARDS.md` with its tier and exception and has an entry in `examples.md`, or the user has declined it.
