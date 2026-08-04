---
name: tune-loop
description: Run the hyperparameter search for a fine-tune as a recorded loop — one axis per step, a prediction before every run, a grid that shows what was tried, and a decision about what to tune next. Use whenever the user says "tune", "sweep", "search hyperparameters", "find the best learning rate", "optimize this model", or asks what to try next; whenever a smoke run has passed and real training is about to start; and for any regime — supervised learning, SFT, DPO/KTO/ORPO, reward modelling, GRPO/PPO/RLOO/RLVR. It owns the search, not the code being searched.
---

# tune-loop

A fine-tune is not tuned by running experiments. It is tuned by **running one experiment,
writing down what it changed the number to, and letting that decide the next one.** This
skill is that loop, and the grid it produces is its interface.

The loop's job is to make every run answer a question that was asked before it started.
A run launched without a written prediction produces a number that can be rationalised
into agreement with any belief, which is the failure mode this whole structure exists to
prevent.

Four companions, read when their pointer fires:

- [`tune-preflight`](../tune-preflight/SKILL.md) — before **every** launch. Does it fit,
  how long, what breaks first.
- [`run-triage`](../run-triage/SKILL.md) — after every launch. Healthy, kill, or fix.
- [`escalate`](../escalate/SKILL.md) — when the loop is stuck, over budget, or about to
  do something expensive and irreversible.
- [`ml_logging`](../ml_logging/SKILL.md) — run names, config snapshots, the metric
  vocabulary, the grid-as-data spec. Read before naming anything.

Findings land per [`notes`](../notes/SKILL.md): the row in `experiments.md`, the read of
it in `notes.md`, the trap in `learnings.md`.

---

## Entry gate

Tuning cannot start until five things exist. If any is missing, that is the work — go to
[`rl-env-mvp`](../rl-env-mvp/SKILL.md) for an RL project or [`mvp`](../mvp/SKILL.md)
otherwise, and come back.

| Required | Why the loop is meaningless without it |
|---|---|
| A **headline metric**, held out, greedy or fixed-seed | Nothing to rank rows by |
| A **baseline** under the current frozen controls | Every later claim is a delta against it |
| A **smoke run** that completed with finite gradients | You would be tuning a broken loop |
| A **fixed experiment budget** — steps or wall clock | Rows measured over different budgets are not comparable |
| A **journal** — `experiments.md`, `notes.md`, `learnings.md` | A result not written down gets re-run in three weeks |

**The experiment budget is a constant, declared in the block header.** Every run in a
block trains for the same number of steps *or* the same wall clock — pick one, say which,
and hold it. Fixing wall clock makes architecture and batch changes comparable at equal
cost; fixing steps makes them comparable at equal data. Neither is wrong; silently mixing
them is.

---

## The three kinds of setting

The same vocabulary [`rl-env-mvp`](../rl-env-mvp/SKILL.md) defines, and it governs every
regime, not just RL. Conflating these is what makes a tuning log unreadable.

| Kind | What it is | Changing one means |
|---|---|---|
| **Frozen control** | Held constant on purpose | **Every earlier row is invalidated** — start a new block |
| **Axis** | What you are searching | A new row in the current block |
| **Observed** | A consequence, not a choice | Nothing — it explains a ranking, it is not searched |

Which is which is a per-project decision made once and written in the block header. A
setting that is an axis in one project is a frozen control in another; what is not
negotiable is that a run declares which it treated it as.

---

## The iteration

Seven steps. Steps 1 and 6 are the ones that get skipped, and they are the ones that make
the rest worth doing.

### 1. Write the prediction before the run

In `notes.md`, before launching:

```markdown
**Next: lr 1e-4 → 2e-4.** Expect the metric to keep climbing — 5e-5 → 1e-4 bought
+0.015, and dead-group fraction has not moved, so the step size is not yet the
constraint. **Falsified if** the metric lands within ±0.012 of 0.155, or dead-group
rises above 0.05.
```

A prediction with no falsifier is a chore, not an experiment. If you cannot say what
result would change your mind, you do not yet have a hypothesis — you have a habit.

### 2. Change exactly one axis

Bounded proposals. One axis, one step. The temptation to move two is always the same —
compute is expensive and both look promising — and the cost is always the same: a result
that cannot be attributed.

Two exceptions, both explicit:

- **A coarse grid on one axis** is one step. Three learning rates a decade apart is a
  line search, not a multi-axis change.
- **Genuinely coupled pairs** — learning rate with batch size, LoRA rank with alpha, k
  with temperature — may move together *when the coupling is the hypothesis*. Say so in
  the prediction, and expect to disentangle them later.

Pick the axis from [`hparam-priors`](../hparam-priors/SKILL.md) when it exists; until
then, the ordering rule is: **the axis whose failure mode you have not yet ruled out**,
biggest lever first.

### 3. Preflight

[`tune-preflight`](../tune-preflight/SKILL.md). Non-negotiable, including for "it is the
same as last time but the batch is bigger" — that is precisely the run that OOMs at step
3 and costs an hour.

### 4. Launch

One run, its own name, its own directory, its own config snapshot, per
[`ml_logging`](../ml_logging/SKILL.md). A tuning run is an ordinary run; if a cell cannot
be re-run on its own from its snapshot, the sweep has become a second training path.

### 5. Triage

[`run-triage`](../run-triage/SKILL.md), early — inside the first 10–20% of the budget, not
at the end. Most doomed runs are diagnosable in the first minutes, and the compute after
that point is spent proving something already known.

### 6. Record — immediately, not at end of day

Append the row to `experiments.md`. Then write the read in `notes.md`: what moved, what
did not, and **whether the prediction from step 1 survived**.

A result that contradicts the prediction is the highest-value output available and the one
most easily rationalised away an hour later. Write it while it stings.

**A crashed or OOM'd run is a row.** It records where the configuration became unstable,
which is usually the boundary you were looking for. Dropping it leaves a grid that reads
as complete.

### 7. Decide

One of five, and say which out loud:

| Verdict | When | Next |
|---|---|---|
| **Climbing** | Delta exceeds the noise floor in the predicted direction | Continue the axis, same direction |
| **Peaked** | Two consecutive steps inside the noise floor, or a reversal | Freeze it at the best value, move to the next axis |
| **Blocked** | The next value does not fit, or breaks a constraint | Record the blocker; [`escalate`](../escalate/SKILL.md) if a mitigation would change a frozen control |
| **Broken** | Triage says bug, not instability | Stop tuning. No axis value fixes a bug |
| **Stuck** | Three consecutive runs inside the noise floor across axes | [`escalate`](../escalate/SKILL.md) |

---

## Is the delta real

**Measure the noise floor once per block, and put it in the header.** Re-run the current
best configuration with two additional seeds and take the spread. It costs two runs and it
is the difference between a search and a random walk.

Until it is measured, no row is a win. Afterwards, a delta inside the floor is recorded as
**within noise** — not as a smaller improvement, and not as a tie broken by preference.

Three failures this prevents, all of which look like findings:

- A best-of-N winner chosen from a grid where every cell is inside the floor. The grid
  guarantees a winner; the floor decides whether it means anything.
- A "regression" that triggers a rollback of a change that was actually fine.
- An axis declared peaked when the search never left the noise.

Where seeds are too expensive to spare, say so explicitly and state the floor as unknown —
an unmeasured floor stated as a limitation is honest; an unmeasured floor treated as zero
is not.

---

## Grid or line search

The default is a **sequential line search**: one axis, one value at a time, each result
choosing the next. It is cheaper than a grid and every run is informed by all previous
ones.

Launch a real grid only when all three hold: the axes are **coupled** so the best value of
one depends on the other, each cell is **cheap** relative to the budget, and the cells can
run **concurrently** on hardware you already have. Then it is declared as data per
[`ml_logging`](../ml_logging/SKILL.md), with the hypothesis and the falsifier in a comment
at the top, and it is preflighted **at its concurrency**, not per cell.

A grid run sequentially is a line search with the informativeness removed.

---

## Blocks, and when to open a new one

One block per frozen-control set. The header states its own controls, its own budget, its
own baseline, its own noise floor, and what changed from the previous block.

Open a new block when a frozen control moves — a different base model, adapter rank,
prompt, reward shape, dataset, eval protocol, precision, or sequence length. **Do not
append to the old one.** This is the entire point of the structure: it is what stops a
baseline from silently moving while every earlier number quietly stops meaning what it
used to.

A new block starts with a re-measured baseline and, if anything is going to be compared
across blocks, a re-run of the previous block's best under the new controls. That bridge
run costs one experiment and is the only legitimate way to compare across blocks.

---

## Stopping

Stop the loop, do not drift out of it. Four legitimate ends:

| End | Test |
|---|---|
| **Converged** | Every axis in the block is peaked or blocked, and the untested column is empty |
| **Good enough** | The metric has cleared the target stated at intake |
| **Out of budget** | The budget from intake is spent — [`escalate`](../escalate/SKILL.md) before spending more |
| **Stuck** | Three consecutive runs inside the noise floor — [`escalate`](../escalate/SKILL.md) |

Then produce the report: the grid, the coverage table naming every untested axis value,
the ranking, and the queue of next experiments each with its hypothesis, falsifier and
cost. Coverage is what distinguishes "we searched this" from "we tried this once and the
default won by default."

---

## Out of scope

The code being tuned — the trainer, environment, dataset and reward belong to
[`rl-env-mvp`](../rl-env-mvp/SKILL.md) or [`mvp`](../mvp/SKILL.md). Resume policy,
checkpoint retention, and cluster scheduling are per-project decisions. Distributed
training topology is not an axis this loop searches.

---

## Done when

The block header states its frozen controls, its fixed experiment budget, its baseline and
its **measured** noise floor; every run in the block has a prediction written before it and
a read written after it; every axis is marked climbing, peaked, blocked or untested, with
untested values named; crashed and OOM'd runs appear as rows; and the queue holds at least
one next experiment with a stated falsifier and cost — or the loop has stopped for one of
the four reasons above and said which.
