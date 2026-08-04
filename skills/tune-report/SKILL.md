---
name: tune-report
description: Produce the tuning report — the grid of what was tried, the coverage of what was not, the ranking against the noise floor, and a ranked queue of what to finetune next. Use when the user asks "where are we", "what have we tried", "what should I tune next", or wants a status on a sweep; at the end of a block; before escalating or stopping; and when picking up a project whose runs exist but whose story does not.
---

# tune-report

The report is the artifact a human reads to decide what happens next. It has one job:
**make the next decision obvious, and make the reasons for it checkable.**

It is not a summary of the runs. A summary answers "what happened"; this answers "what is
still unknown, and what is the cheapest way to find out". The coverage table and the queue
are the parts that do that, and they are the parts that get left off.

Written from the record: `journal/experiments.md` for the entries and their reads,
`journal/learnings.md` for the traps, the run directories and `configs/` for anything the
journal is missing — see [`ml_logging`](../ml_logging/SKILL.md) and
[`notes`](../notes/SKILL.md). The entry format itself is
[`tune-loop`](../tune-loop/SKILL.md) step 6. Produced at the end
of a block, on escalation, and whenever asked.

**No code.** The report is written by reading the record. If reconstructing it from run
directories is painful, the fix is the logging, not a script.

---

## The five sections

In this order. A reader who stops after the first two should still know where the project
stands.

### 1. Header — what these numbers mean

The frozen controls, the fixed experiment budget, the spend against the agreed budget, the
baseline **measured under these controls**, and the **measured** noise floor. Plus one line
saying what changed from the previous block and whether anything is comparable across the
boundary.

Without the noise floor the table below it is a ranking of coin flips, so if it has not
been measured, say that in the header rather than omitting it.

### 2. The grid

One row per run, ranked by the headline metric. Rules that keep it readable and honest:

- **A column only exists if it varied.** An axis with one value across every row belongs in
  the header. This is what stops the grid from becoming a config dump nobody scans.
- **Δ against the best, with `(noise)` marked** on anything inside the floor. A delta
  inside the floor is not a smaller improvement; it is not an improvement.
- **Crashed, OOM'd and killed runs stay in the table**, with the step they died at and the
  peak they reached. They mark the boundary of the feasible region, which is what the next
  [`tune-preflight`](../tune-preflight/SKILL.md) reads.
- **Observed columns sit beside the metric** — step time, peak memory, and the two or three
  diagnostics that explain the ranking in this regime. They explain a result; they are
  never searched.
- **Name any column that is not comparable across rows.** A metric measured under something
  the grid itself varied invites exactly the comparison it cannot support, and a table
  format implies the comparison is legitimate.

### 3. Coverage — what was *not* tried

The section that distinguishes a search from a habit. One row per axis: values tried, the
best, the values **untested**, and a verdict of climbing, peaked, blocked or untested.

**An axis with one value tried is untested, not settled** — including axes nobody chose to
set. A default that has never been varied is the most common thing a coverage table
discovers.

### 4. What to finetune next

Two to four candidates, ranked, each with:

| Field | Why |
|---|---|
| **Change** | One axis, or a named frozen-control change |
| **Hypothesis** | What you expect and why, from a number in the grid above |
| **Falsified if** | The result that would kill it. No falsifier, no experiment |
| **Cost** | Wall clock or GPU-hours, from measured step time |
| **New block?** | Whether it invalidates every row above |

**Rank by information per unit cost, not by expected improvement.** The experiment most
worth running is often the cheap one that closes a door permanently — a result that rules
out a whole direction is worth more than one that nudges the metric, and it is the kind of
experiment that never gets queued when the ranking is by hoped-for gain.

Stop at four. A queue longer than that is a list of everything conceivable, and it moves
the decision back onto the reader.

### 5. Blocked and open

What cannot proceed and what it needs — a decision, hardware, data, or an answer from the
user. Anything here that needs a human is the content of an
[`escalate`](../escalate/SKILL.md) message; do not bury a blocker at the bottom of a report
and consider it raised.

---

## Template

```markdown
# Tuning report — 2026-08-03 17:20 · block 2

**Best: `calm-heron` 0.155** (baseline 0.115, +0.040). Three runs since have been inside
the noise floor; the block's axes are exhausted.

**Frozen:** qwen-3b · bf16 · LoRA r=16 · prompt `search` · reward `solve_dominant`
**Experiment budget:** 20 min/run, fixed · **Spent:** 4.7 of 12 GPU-h
**Eval:** greedy, cap 1024, 200 held-out · **Baseline:** 0.115 · **Noise floor:** ±0.012 (3 seeds @ lr 5e-5)
**Changed from block 1:** prompt terse → search. Block 1 rows are not comparable; the bridge
run is `brave-mantis`.

| started | run | lr | prompts/step | k | temp | **metric** | Δ vs best | step s | peak GB | dead grp | status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 08-03 19:55 | `bold-pika`   | 1e-4 | 8 | 16 | 1.0 | **0.158** | +0.003 (noise) | 31 | 74 | 0.01 | ok |
| 08-03 15:19 | `calm-heron`  | 1e-4 | 8 | 8 | 1.0 | **0.155** | — | 16 | 61 | 0.03 | ok |
| 08-03 18:30 | `wry-tapir`   | 1e-4 | 8 | 8 | 0.7 | 0.151 | −0.004 (noise) | 16 | 61 | 0.06 | ok |
| 08-03 17:02 | `swift-lynx`  | 2e-4 | 8 | 8 | 1.0 | 0.149 | −0.006 (noise) | 16 | 61 | 0.09 | ok |
| 08-03 14:02 | `brave-mantis`| 5e-5 | 8 | 8 | 1.0 | 0.140 | −0.015 | 16 | 61 | 0.02 | ok |
| 08-03 16:11 | `witty-otter` | 5e-5 | 4 | 8 | 1.0 | 0.121 | −0.034 | 9 | 42 | 0.02 | ok |

| 08-03 20:41 | `glum-shrew`  | 1e-4 | 16 | 8 | 1.0 | — | — | — | **79 (OOM @ step 3)** | — | **crashed** |

**Ranked by the metric, dated by `started`** — two different orders, on purpose. The ranking
answers "what won"; the dates answer "what did we know when", which is what makes a row taken
before a bug fix visibly different from one taken after.

### Coverage

| axis | tried | best | untested | verdict |
|---|---|---|---|---|
| learning rate | 5e-5, 1e-4, 2e-4 | 1e-4 | — | **peaked** — 2e-4 within noise, dead-grp rising |
| prompts/step | 4, 8, 16 | 8 | — | **blocked** — 16 OOMs at cap 1024 |
| k | 8, 16 | 16 | 4 | within noise, and 2× the step time |
| temperature | 1.0, 0.7 | 1.0 | 1.2 | untested |
| generation cap | 1024 | — | 768 | **untested** — frozen control, never varied |

### What to finetune next

| # | Change | Hypothesis | Falsified if | Cost | New block |
|---|---|---|---|---|---|
| 1 | cap 1024 → 768 | truncation 0.04 says the headroom is unused; 30% cheaper steps buys ~4 more runs from the same budget | truncation > 0.08 or metric drops > 0.012 | 20 min + baseline | yes |
| 2 | reward shape → `graded` | dead-grp 0.01–0.09 is thin spread; partial credit widens the gradient | dead-grp does not fall and metric does not clear 0.167 | 1.5 h | yes |
| 3 | base model 3B → 7B | 0.155 may be a capacity ceiling rather than a tuning one | 7B lands within noise of 0.155 | 4 h + preflight | yes |

Ranked by information per hour: #1 is cheap and pays for itself in budget if it holds;
#2 and #3 test the same ceiling-vs-signal question, and #2 is a third of the cost.

### Blocked and open

- **prompts/step 16** needs gradient checkpointing (+~25% step time) — block-surviving, but
  it changes the budget arithmetic. Decision needed.
- **Every remaining candidate opens a new block.** This block is done; see the escalation
  on the `calm-heron` entry, 2026-08-03 17:25.
```

---

## Multiple blocks

Never merge blocks into one table. Lead with a block index — one row per block, its frozen
controls, its baseline, its best — and then report the current block in full.

**A number from another block is comparable only through a bridge run**: the previous
block's best configuration re-run under the new controls. Name the bridge run wherever a
cross-block claim is made, or state that the comparison is not supported.

---

## Honesty rules

**Say what was not run.** A grid cut short, a cell skipped, a seed not repeated, an axis
sampled at two of five planned values — all of it. A report that omits them reads as
complete, and the missing cell is usually the informative one.

**Distinguish measured from believed** in every read. The grid is measured; a diagnosis of
why a row lost is usually not.

**Failures rank equally with successes.** A run that closes a direction permanently goes in
the report at full weight, and it belongs in the queue's reasoning rather than in a
footnote.

---

## Out of scope

Deciding what to run — that is [`tune-loop`](../tune-loop/SKILL.md). Diagnosing a single
run — [`run-triage`](../run-triage/SKILL.md). Plots and dashboards: this report is text so
it can be diffed, pasted into an escalation, and read on a phone.

---

## Done when

The header states the frozen controls, the fixed budget, the spend, the baseline and the
measured noise floor; the grid is ranked, marks within-noise deltas, keeps crashed rows,
and has no column that did not vary; every axis appears in coverage with its untested
values named; the queue holds two to four candidates each with a falsifier, a cost and a
new-block flag, ranked by information per unit cost; blockers are stated at the top of
their section, not buried; and a reader who has not seen the project can say what to run
next and why.
