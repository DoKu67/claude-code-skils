---
name: minimal-cover
description: "Cut any list of items (requirements, hypotheses, specifications, tasks, tests) to the smallest set that still covers the goals it serves, so a human can read the whole list and change it. Works out the goals, builds a coverage table, deletes items until removing any one more would leave a goal uncovered, flags over-specific goals, tolerances and hard constraints with a recommendation each, and shows what dropping each remaining item would cost. The user approves once, at the end. Use when the user runs /minimal-cover, says \"too many requirements\", \"cut this down\", \"what is the minimal set\", \"this spec is bloated\", \"which of these hypotheses do we actually need\", and whenever a list of requirements or hypotheses has just been drafted and is about to be approved."
---

# minimal-cover

Too many requirements, specifications or hypotheses is a defect in its own right. A list
the user cannot read in one sitting is a list they cannot change, and an unchangeable list
stops being theirs. This skill takes **any list of items** and returns the smallest set
that still does the job, then lets the user decide what the job is.

"Minimal" is only defined against something. So the skill works in two halves: first make
the goals explicit, then cut the items against them. The user sees both and approves both.

Callers: [`build`](../build/SKILL.md) on draft requirements, and
[`experiment`](../experiment/SKILL.md) on hypothesis cards. It can also be run directly on
an existing `SPEC.md` or backlog that has grown.

---

## 1. Goals

Infer the goals `G-1 … G-m` the items serve, from the caller's context and the items
themselves. What a goal looks like depends on the items:

| Items | A goal is |
|---|---|
| Requirements | an outcome the user wants ("finance can open the export") |
| Hypotheses | a decision the user has to make ("pick the serving engine") |
| Tasks, tests | a requirement or claim they discharge |

Keep goals few, and in the user's words where they exist.

**Flag over-specific goals.** A goal that fixes a number, a device, a library or a method
before anything has been measured ("p50 under 180 ms on an A100") is usually a guess
standing in for the real goal ("faster than today on the same hardware"). Flag it with a
recommended rewrite; do not rewrite it silently.

## 2. Coverage table

Rows are items, columns are goals, and a cell is marked when the item serves that goal.

```markdown
| Item | G-1 export | G-2 share with finance | G-3 audit trail |
|---|---|---|---|
| R-1 export to CSV | x | x | |
| R-2 export to XLSX | x | x | |
| R-3 log every export | | | x |
| R-4 export includes timestamps | | | x |
```

An item that serves no goal is either out of scope or a sign of a missing goal. Ask which
at approval; do not quietly add a goal to save it.

## 3. Delete loop

Try removing each item in turn. Remove it if:

- it covers no goal; or
- every goal it covers is still covered by the items that remain; or
- it **follows from the remaining items**: ask [`code-proof`](../code-proof/SKILL.md)
  whether "I-k holds whenever the rest hold", and delete only on **Proved**. Disproved or
  Unresolved keeps the item.

For hypotheses, also delete a card whose every answer leads to the same decision, or whose
answer another card already settles.

**Keep** any item whose removal would leave a goal uncovered. Record a one-line reason for
every deletion; the user will read them. Repeat until a full pass removes nothing.

## 4. Stopping rule

Stop when **no single remaining item can be removed without uncovering a goal**. The result
is equivalent to the input for the stated goals: every goal is still covered, and every
deletion has a stated reason (no unique coverage, or a Proved implication).

This is a local minimum, not a claimed global one; say so if two different minimal sets
exist, and show both.

## 5. Flags

Flag **every** number, threshold and "must" in the remaining items and goals, with a
recommendation the user can answer yes, no, or with a change:

| Flag | Example | Recommendation |
|---|---|---|
| Over-specific goal | G-3 p50 under 180 ms on an A100 | Rewrite as: faster than today on the same GPU |
| Tolerance with no measured basis | R-2 outputs match within 1e-3 | Set it from the noise floor (the system re-run against itself) |
| Arbitrary bar | H-1 at least 10% fewer GPU-s | Drop the bar; report the measured change and you decide |
| Hard constraint | H-2 must fit in 80 GB | Keep if 80 GB is the real hardware limit; otherwise measure it |

A tolerance is justified only by a measurement or a physical limit the user confirms. Say
which one, or recommend removing it.

## 6. Less than minimal

For each remaining item, show the goal the user loses by deleting it, so cutting further is
one reply:

```markdown
| # | Item | Only goal it covers | If you delete it |
|---|---|---|---|
| 1 | R-3 log every export | G-3 audit trail | G-3 is dropped from scope |
| 2 | H-4 CPU fallback | the "keep a CPU path?" decision | that decision is made without data |
```

## 7. Approve, once, at the end

Show the user one screen: the goals (with flags), the minimal set, the deletions with their
reasons, the flags with recommendations, and the less-than-minimal table. They reply per
row: keep, drop, or change ("G-3 yes; flag 2 yes; flag 3 keep 10%; delete #2").

If they edit any goal or item, **rerun steps 2–6 on the edited input** and show the new
screen. Repeat until they approve. Return the approved set, with its goals and deletion
reasons, to the caller.

---

## Out of scope

Deciding what the goals should be; the skill proposes and the user decides. Writing
`SPEC.md` or the cards; the caller does that with the approved set. Merging items into new
wording beyond what a flag's recommendation proposes.

## Done when

Every goal is covered by the returned set; no single item can be removed without uncovering
a goal; every deletion has a reason, and every implication-based deletion has a Proved
verdict behind it; every number, threshold and "must" has been flagged; and the user has
approved the goals, the set and the flags.
