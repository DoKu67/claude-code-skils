---
name: tldr
description: Summarize where something stands in a fixed five-section format — Summary, Goal, Blockers, Next Steps, Figures. Use when the user says "tldr", "summarize", "recap", "where are we", "give me the short version", or asks for a status update; when handing work off or closing out a long session; and when a thread has grown long enough that the current state is no longer obvious from reading it.
---

# tldr

One format for any task — a refactor, an investigation, a migration, a training run —
always the same five sections, in this order. The value is in the fixed shape —
a reader who has seen one knows exactly where to look for the number, the blocker and the
next action, and does not have to read prose to find out whether there is one.

**Target: 30 seconds to read.** If it takes longer, it is a report, not a TLDR.

---

## The format

```markdown
Summary:
- <1-2 sentences: what this is and where it stands>
- <bullet>
- <bullet>

Goal:
- <bullet>

Blockers:
- <bullet, or "None">

Next Steps:
- <bullet>

Figures:
| <field> | <field> |
|---|---|
```

**All five headings always appear**, even when a section is empty — an absent *Blockers*
section is ambiguous between "nothing is blocked" and "nobody checked". Write `None`.

---

## What goes in each

| Section | Holds | Never |
|---|---|---|
| **Summary** | 1–2 sentences of what this is and where it stands, then bullets for the substance | A preamble, or a restatement of the request |
| **Goal** | What success looks like — the user's stated objective, restated in their terms | A goal you inferred and never checked, or a task list |
| **Blockers** | What is stopping progress, and **what would unblock it** — a decision, an answer, a resource | Risks that are not currently blocking anything |
| **Next Steps** | Ordered, each starting with a verb, each naming **who does it** | Anything you have already done, or vague intent |
| **Figures** | The numbers and artifacts — measurements, counts, run names, file paths, before/after | A table restating bullets that are already above |

Four rules that keep it honest:

- **Five bullets per section is the ceiling**, one line each. If a section needs more, the
  TLDR is standing in for a document that should exist.
- **A blocker names its unblocker.** "Waiting on X" is not a blocker; "waiting on your
  decision between A and B" is, because it says what to do about it.
- **Figures carry information found nowhere else.** If the table restates the bullets, cut
  it and write `None`. Column headers name the field, not the item.
- **Never invent a section to fill it.** `None` is a legitimate and useful answer in every
  section except Summary.

---

## Honesty

The failure this format invites is a status that reads as further along than the work is.
Three rules against it:

- **Distinguish done from believed-done.** Something is done when it ran and you saw the
  output. Anything else is in *Next Steps*, not *Summary*.
- **Blockers include the ones the user has not seen yet.** A TLDR that omits a problem
  because it has not been raised is worse than no TLDR, because it is believed.
- **Failures get the same weight as successes.** A step that did not work belongs in
  *Summary* at full size, not softened into a *Next Step*.

---

## Where to look

**Read the state; do not recall it.** A TLDR written from the conversation over-reports
done-ness — the conversation holds intentions as well as outcomes, and in hindsight they read
alike. This changes what you read *before* writing, not how much you write.

| Source | Answers |
|---|---|
| `TaskList` | what is in flight, what is blocked, what actually finished |
| `git status --short`, `git log --oneline` | what landed versus what is still uncommitted |
| Background tasks and monitors | what is still running, however finished it feels |
| `PLAN.md` and the project's journal | the *Goal* in the user's own words; the numbers for *Figures* |
| `~/.claude/skills-staging/LEDGER.md` | decisions waiting on the user — *Blockers* they have not seen |

Not every source exists in every project, and a missing one is not a gap. **Inferring a
source's contents instead of opening it is.** The two that change the output most:
uncommitted work belongs in *Next Steps* rather than *Summary*, and a still-running task is
never reported as its expected result.

---

## Example

```markdown
Summary:
- The tuning skill set is built and committed; the reflection loop is live but untested on a
  real session.
- 10 new skills in `~/.claude/skills/`, all cross-links verified.
- `~/.claude/skills/` is now a git repo — baseline commit `31de571`, 30 files tracked.
- Nothing has been exercised on an actual training project yet.

Goal:
- A composable skill set that takes a model from scaffold to tuned, records every run, and
  escalates before an OOM or a wasted budget.
- Skills that improve from feedback without accumulating stale rules.

Blockers:
- None blocking. Open decision: whether `mvp`/`sft-env-mvp`/`rl-env-mvp` should scaffold an
  `environment.yml` and pytest config by default — needs your yes/no.

Next Steps:
- You: run `/reflect` on this session to see the staging format on real signals.
- Me: stage the conda/pytest scaffolding rule if you want it.
- Me: exercise `tune-loop` against a real repo and fix what the entry gate gets wrong.

Figures:
| item | value |
|---|---|
| skills added | 10 |
| tracked files in skills/ | 30 |
| staged candidates | 0 |
| VRAM ceiling for preflight | 31.8 GiB |
```

---

## Out of scope

**This skill prints; it does not write files.** Where a durable record belongs depends on
the project — an entry's Summary in `journal/experiments.md` if it has a journal per
[`notes`](../notes/SKILL.md), `PLAN.md` for a decision, a commit message otherwise. Write to
a file only when asked.

When the subject is a hyperparameter search, the deliverable is
[`tune-report`](../tune-report/SKILL.md), not this — its grid and coverage tables are the
point. A TLDR may front a report, but it does not replace one.

---

## Done when

All five headings are present in order; `None` appears wherever a section is genuinely
empty; Summary opens with 1–2 sentences; no section exceeds five one-line bullets; every
blocker names what would unblock it; every next step starts with a verb and says who does
it; the Figures table carries numbers or artifacts that appear nowhere else, with headers
naming the field; and nothing is reported as done that was not observed to run.
