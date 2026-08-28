---
name: plan-doc
description: Keep the plan document in a fixed shape — what the project is for, what is decided, and the next three steps — so it stays readable as the project changes under it. Use whenever writing or revising a PLAN.md or equivalent, when a result invalidates something the plan asserts, when a plan is being superseded or renamed, when steps need numbering, and when a plan has grown long enough that nobody reads it. Also use when the user says "write a plan", "update the plan", "what's the plan", or asks where a decision is recorded.
---

# plan-doc

A plan is the answer to *"what is this project for, what has been settled, and what happens
next"*. It is not a record of what happened — that is the journal — and it is not a
specification.

Plans fail in one direction only: they grow. Every result feels worth recording, every
abandoned idea feels worth explaining, and a document nobody reads stops constraining
anything. The sections below exist to give each kind of content one home, so that growth in
one place is visibly growth in the wrong place.

## The shape

```markdown
# <NAME> — <one line: what this project is for>

**Status · <date> · <state>.** Where it stands in one line, with a pointer to the evidence.

## The objective     what success is, falsifiably, and the bar it must beat
## Constraints       non-negotiable, each with the failure that bought it
## Previous steps    every closed step, one row, ✅ or ❌, with a pointer
## Next steps        at most three or four, each with its falsifier and its cost
## Decided           settled choices with reasons, so none is re-litigated
## Out of scope      with the reason each was excluded
## Open              each unknown paired with what would resolve it
```

**All seven sections appear even when nearly empty.** An absent *Out of scope* reads as "nothing
was excluded" when it usually means "nobody wrote down why we dropped that". `None` is a
legitimate entry.

Order matters and is not arbitrary: a reader arriving cold needs the purpose, then the rules
they cannot break, then what to do next. Everything after *Next steps* is reference material
for when a question comes up.

## Status is one line, and it is dated

The status line is the most-read text in the repo and the first thing to rot. One line, a
date, the state, and a pointer:

```markdown
**Status · 2026-08-06 · blocked on a decision.** Step 1 was measured and falsified: the judge
does not predict the user's accept/reject (AUC 0.480, chance band [0.33, 0.67] at n=40). Runs
`08_06_12_44_49` and `…_49b` in `journal/experiments.md` hold the numbers.
```

Not a paragraph, not a changelog. If the status needs a paragraph, the thing being described
is a *result* and belongs in the journal with a one-line summary here.

## Previous steps — one row per closed step, and a marker

A plan that only looks forward makes the same mistake twice. Someone arriving cold cannot tell
whether a direction is untried or already dead, and neither can you in three weeks.

```markdown
## Previous steps

| Step | Outcome | What it established |
|---|---|---|
| Noise floor of the score | ✅ | Floor measured; option order moves it 4.06× that floor · run `08_06_00_31_51` |
| Smoke test vs the 12 corruptions | ✅ | Survived, +2.34× floor on 10 pairs. Did not stop the project |
| Separate gold from realistic negatives | ❌ | 54.4% pairwise against a 61.6% ceiling. Too thin to train against |
| Does a better solver fix the margin? | ❌ | Falsified — 18pp of accuracy buys 3pp of win rate |
| Judge predicts the user's accept/reject | ❌ | AUC 0.480, inside the chance band · runs `08_06_12_44_49`, `…_49b` |
```

Rules that keep this from becoming the results dump the plan is meant to avoid:

- **One row per step, one clause each.** The row says what the step *established*, not what it
  measured. A number appears only when it *is* the conclusion.
- **✅ means the step ran and its falsifier did not fire. ❌ means the falsifier fired.** Both
  are outcomes, and a plan where nothing is ❌ is a plan whose falsifiers were too weak.
- **Every row points at its run**, so the detail is one hop away and does not need repeating.
- **Rows are append-only.** A closed step never leaves this table, even when the whole approach
  is superseded — that is precisely when it is most worth knowing the step was tried.
- **Steps dropped without running get ❌ with the reason**, distinguished in the clause:
  *"removed unrun — assumed a judge that predicts shipping"*. A dropped step is information too.

The check-and-cross pair is deliberate: the glyphs differ in **shape**, so the marker survives
being read by someone who does not distinguish red from green, and survives being printed in
black and white.

## At most three or four next steps

This is the rule the skill exists for, and the one most often broken with the best intentions.

**Depth past the third step is speculation.** Early in a project you are searching broadly —
trying a direction, learning it is wrong, trying another. Each result reshapes the problem, so
a fourth and fifth step written now are written against assumptions the second step will
probably overturn. Writing them costs real time, and worse, it creates the feeling that the
route is settled when it is still being searched.

Symptoms that the cap is being broken:

- Steps that only make sense if an earlier step succeeds, stated as though it will
- A step whose falsifier is vague, because nobody yet knows what would count as failure
- Reordering steps repeatedly without any of them running

**Plan deeply only after a direction has survived contact with evidence.** Then the steps are
about execution rather than discovery, and a longer sequence is honest. Until then, three.

**When a step is removed, say whether it was reordered or dropped.** A step deleted because it
assumed something now known to be false is a finding; silently disappearing it loses that.

## Results never appear in the plan

The single most common way a plan doubles in size.

| Content | Home |
|---|---|
| What a run produced, with its numbers | `journal/experiments.md` |
| What a result *means*, and what changed because of it | `journal/notes.md` |
| A trap that cost time | `journal/learnings.md` |
| What was decided, and why | **the plan**, under *Decided* |
| What is still unknown | **the plan**, under *Open* |
| That a step ran, and whether its falsifier fired | **the plan**, under *Previous steps* — one row, one clause |
| What the system must do, whatever else changes | `SPEC.md` — see [`spec-doc`](../spec-doc/SKILL.md) |

The test: **if the text would need rewriting after the next run, it does not belong in the
plan.** A number is a result. "We chose softmax over raw log-probability because raw is
length-biased" is a decision and stays.

*Previous steps* is the deliberate exception, and it is narrow: a row records **that** a step
closed and **which way**, never the measurement. The moment a row needs a second sentence, the
detail belongs in the journal and the row should point at it instead.

Where a plan must reference a result, reference it — one clause and a run name — rather than
restating it. See [`notes`](../notes/SKILL.md) for the journal's own shape.

## The plan is the route; the spec is the contract

A plan changes every time a result lands — that is what it is for. A specification does not:
it states what the system must do whatever the route turns out to be, and it is written and
changed by **the human alone**. See [`spec-doc`](../spec-doc/SKILL.md) for its shape and for
the rule that a failing requirement is fixed in the code or escalated, never edited away.

The boundary is one question: **would this sentence still be true if the plan were thrown
away and the project restarted from scratch?**

- Yes → it is a requirement, and belongs in `SPEC.md`.
- It would need rewriting after the next run → journal.
- Otherwise → the plan.

**A *Decided* entry that describes system behaviour has outgrown the plan.** "We chose
softmax over raw log-probability because raw is length-biased" is a working decision and
stays. "Scores SHALL be length-invariant" is an obligation on the system — propose it to the
user as a requirement, and leave the plan entry as a one-clause pointer to the ID once they
accept it. Claude never writes it into the spec unilaterally.

Where a next step exists to satisfy a requirement, name the ID in the step. That is what
makes it visible when a step closes ✅ and its requirement is still ❌ in the conformance
table — the step delivered something, but not the obligation it claimed.

## Only the plan numbers steps

If two documents both number things, they collide, and the collision is silent because each
file reads consistently on its own.

**Steps are numbered in the plan. Everywhere else refers to those numbers.** A journal queue
orders and annotates the plan's steps; it does not name new ones. When the queue wants an item
the plan lacks, the answer is to add it to the plan, not to invent a number.

Three documents number things, and they number different things: the plan numbers **steps**,
the spec numbers **requirements** (`R-4`), and [`sprint-tasks`](../sprint-tasks/SKILL.md)
numbers **tasks**. Always write the prefix — *step 3*, `R-3` and *Task 3* are three different
objects, and a bare "3" is a collision that reads correctly in every file and means the wrong
thing across them.

## Superseding a plan

A plan that has been replaced is evidence, not clutter, and deleting it destroys the record of
why the current approach exists.

- **Rename, do not delete:** `PLAN.md` → `PLAN_deprecated.md`, or move it under an archive
  directory. Pick one convention per repo and keep it.
- **The old plan's status line points forward**, and the new plan's points back, in one clause
  each.
- **Sweep every reference.** A rename ripples further than expected — docstrings, journal
  entries, the auto-loaded context file, other plans. Run
  [`consistency`](../consistency/SKILL.md) after, and check that every link still resolves.
- **The new plan does not re-argue the old one.** One table of what closed the previous
  approach, with pointers. The reasoning already exists in the journal.

## Constraints earn their place by having cost something

*Constraints* is not a style guide. Each entry is a rule that a dead design or a wasted run
paid for, and each states what it prevents:

```markdown
1. **Gates are a hard constraint, never a reward term.** Trip a gate → 0. A positive weight is
   farmable: 506 of 635 corpus failures were a single length gate.
```

A constraint with no cost attached is a preference, and preferences belong in
[`coding-standards`](../coding-standards/SKILL.md) or nowhere.

## Length

**A plan a person will not read constrains nothing.** Signs it has outgrown the format:

| Symptom | What it usually is |
|---|---|
| Over ~120 lines | results have leaked in, or steps have accumulated past the cap |
| A section about one specific step | that step's detail belongs in the journal or in the code |
| Two sections covering the same ground | one is stale; find out which |
| Module layout, class structure, file trees | design, not planning — see [`mvp`](../mvp/SKILL.md) stage 3 |

Shortening a plan is not losing information: nearly everything cut is either already in the
journal or reconstructible from git history.

## Out of scope

Judging whether the plan's *content* is right — that is the work. Writing the code the plan
describes — [`mvp`](../mvp/SKILL.md). Recording what happened — [`notes`](../notes/SKILL.md).
Reporting status to a person — [`tldr`](../tldr/SKILL.md), which reads the plan rather than
editing it.

## Done when

All seven sections are present in order; the status line is one dated line with a pointer;
*Previous steps* has a row per closed step marked ✅ or ❌ with a pointer to its run; *Next steps*
holds at most three or four, each with a falsifier and a cost; no run result or number appears
outside a reference to the journal or a *Previous steps* clause; steps are numbered only here;
any superseded plan was renamed rather than deleted with references swept; every constraint names
what it prevents; and the whole document can be read in a sitting.
