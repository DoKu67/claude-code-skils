---
name: rl-env-mvp
description: Scaffold a minimal, readable RL environment for GRPO, PPO or RLOO — task source, prompt, rollout, verifier, reward, eval and a pre-training probe — and prove it works before any policy is trained. Use when starting an RL/RLVR project from scratch, when the user asks for an "RL environment", "RL harness", "RLVR setup", "reward function and verifier", or "get an RL loop running on this task", and whenever a task, model, reward, dataset and algorithm need turning into something a human can read, edit and start tuning. Covers the path from zero to a first fine-tune; it does not tune training itself, and preference methods (DPO, KTO, ORPO) are out of scope.
---

# rl-env-mvp

Turn a task, a model and a dataset into an **RL environment a human can read in one
sitting, edit without archaeology, and start tuning the same day.**

The deliverable is everything except the optimizer: the thing that turns a problem into a
prompt, a prompt into rollouts, a rollout into a verdict, and a verdict into a scalar —
plus the measurements that say whether training it could possibly work.

**This skill stops before training.** It does not tune a learning rate or run a policy to
convergence. It ends when a smoke run has proven the loop is alive and the first real
experiment can be launched — [`tune-loop`](../tune-loop/SKILL.md) takes it from there. That boundary is deliberate: almost every hour lost on an RL
project is lost to an environment that was wrong in a way nobody could see, and the fix is
to make the environment measurable before it is trained.

This is [`mvp`](../mvp/SKILL.md) applied to a specific domain. Read that skill for the
staging discipline; read [`coding-standards`](../coding-standards/SKILL.md) before the
first edit; read [`ml_logging`](../ml_logging/SKILL.md) before naming a metric or a run.
Where this skill and `mvp` appear to disagree, `mvp` wins on process and this one wins on
what to measure.

Two reference files, read when their pointer fires:

- [`references/LAYOUT.md`](references/LAYOUT.md) — the file layout, what belongs in each
  module, and the config sections and their responsibilities. Read before writing the first
  file.
- [`references/GATES.md`](references/GATES.md) — the verification ladder in detail, and
  how to read each measurement. Read before the first checkpoint.

---

## Stage 0 — Intake

Six inputs define the environment. Write them down before writing code, because four of
them constrain the other two and the conflicts are cheaper to find on paper.

| Input | What to pin down |
|---|---|
| **Task** | One sentence a stranger could act on. What is the action the policy emits? |
| **Model** | Which policy, and how it is adapted. What fits alongside rollouts on the target hardware? |
| **Dataset** | Generated or fixed? How many? Where does held-out come from? |
| **Environment** | What turns an action into an outcome — a parser, a sandbox, a simulator, a judge? |
| **Rewards to try** | The *set*, not the choice. These become named shapes in config |
| **Algorithms to try** | `grpo`, `ppo` or `rloo` — **defaults to GRPO**. Anything else goes on the deferred list |

### Ask before building

These change the design, not just the parameters, so guessing them is expensive. Ask as
one batch, with your recommendation on each:

1. **Is there a known-good answer per example?** The single most important question in the
   intake. A reference solution lets you assert the harness scores it maximally — the gate
   that catches a broken environment before it wastes a training run. If there is none,
   say so plainly and propose how correctness will be established instead, because
   everything downstream is weaker without it.
2. **What is the task metric, and how does it differ from reward?** Reward is what the
   optimizer climbs; the task metric is what the project is for. If they are the same
   number, the project cannot detect reward hacking. Name both.
3. **What is the time budget for one experiment?** This decides model size, rollout count,
   generation cap and dataset size simultaneously. Under an hour keeps tuning interactive;
   over four hours means two experiments a day and a project that stalls.
4. **What hardware?** The memory ceiling decides adapter-vs-full, batch size, and whether a
   PPO value head is affordable at all. Take the answer and put it in config — do not carry
   settings over from another project's config, where they encoded a different machine.
5. **Can the task be made easier or harder on a dial?** Generated data gives you one;
   scraped data does not. A dial is what lets you *choose* the difficulty band instead of
   betting on it.

### Scope — GRPO, PPO, RLOO

**Three legal algorithms, and they share one environment.** All are online, on-policy-ish
methods that turn rollouts into a scalar reward, so a single environment serves all three
and swapping between them is a config change.

| | Needs from the environment | Metric that says it is working |
|---|---|---|
| **GRPO** *(default)* | k rollouts per prompt; reward **variance within the group** | fraction of groups with zero reward variance |
| **RLOO** | k rollouts per prompt; baseline is the mean of the *other* k−1 | same dead-group fraction |
| **PPO** | one rollout per prompt is fine; a **value head**, and possibly a reward model and reference — up to four models resident | value loss, explained variance, clip fraction |

**GRPO is the default.** Start there unless the intake gives a reason not to, and record in
`PLAN.md` that it was the default rather than a considered choice — so the next person knows
the question is still open.

It earns the slot on three counts. It carries **no value head**, so roughly half the resident
memory of PPO and one fewer network whose own hyperparameters can quietly be the thing that
is broken. Its advantage is just the group-normalised reward, so when a run does nothing the
cause is visible in one number. And **its upgrades are drop-in**, which is why it is a safe
default rather than merely a common one: choosing it costs nothing later.

**Switch deliberately.** PPO if you need per-token credit assignment or already have a
trained reward model. RLOO for the group structure with a lower-variance baseline and no
clipping.

The group-based pair — GRPO and RLOO — make the environment's job harder in one specific
way: **a group whose rollouts all score identically is wasted compute.** The reward must
produce spread across a group of k, not merely rank one answer correctly. Measure it in the
probe before training; this is the metric that most often goes unlogged and most often
explains a dead run.

### The rough plan

Produce a `PLAN.md` before code: the six inputs, the decisions and why they went that way,
the components in build order with the checkpoint each stops at, and **the one risk most
likely to invalidate the whole thing**. A page, not a specification.

It also carries a **deferred** list — everything named at intake that is not on the path to
the first fine-tune. Extra algorithms, the rejection-sampling baseline, reward shapes beyond
the first two, ablations. This is what keeps intake ambition from becoming build scope: a
thing on the deferred list is not forgotten, and it is not blocking either.

Then create a tracked todo list — one task per component, plus the probe, the smoke run, and
the write-up.

---

## Build order

**The goal is zero to a running fine-tune as fast as honestly possible**, because until a
policy is training you are guessing, and after it is training you are measuring. Everything
below is on that path. Anything that is not — a second algorithm, a rejection-sampling
baseline, a reward shape you are curious about, an ablation — goes in `PLAN.md` under
*deferred* and gets built when a result asks for it.

Six components, each stopping at a checkpoint. **Stop and report at every one.** The
problem space is usually unfamiliar, and the point of a checkpoint is to let a wrong shape
be caught while changing it is still free. A checkpoint is a short report and a question,
not a redesign — if it turns into one, the capability list was too long.

Build in this order, because each component's checkpoint depends on the previous one being
trustworthy:

### 1. Input data — `data_loader.py` and `data/`

The task source. Generated or loaded, split into train and held-out, formatted into a
prompt. `data_loader.py` is the code; `data/` is where the inputs themselves live — raw
files, cached downloads, hand-written fixtures, a prompt template if it outgrows a string.
Keeping the two apart is what lets `data/` be gitignored or swapped without touching code.

Held-out must come from somewhere structurally incapable of overlapping train — a distant
seed for generated data, a hash-based split for fixed data. "Shuffle and slice" is how a
contaminated split gets written.

*Checkpoint:* counts, three formatted prompts printed in full, the train/held-out overlap
count (must be zero), and — if generated — proof every example is solvable.

*Ask:* is the difficulty in the band we want, and which knob moves it?

### 2. Environment — `environment.py`

Prompt in, completions out. k rollouts per prompt, with sampling params and the generation
cap read from config. Whether generation goes through a `generate()` call, a serving engine or
a remote worker is a machine-dependent choice and belongs behind this one interface.

The thing to get right is that the **generation cap is usually a cost setting, not a safety
margin**. Where a batch returns only once its longest sequence finishes, a generous cap is
paid on every rollout in that batch — so headroom is not free, and on one measured task
raising it bought nothing but wall clock. Continuous-batched engines weaken this. Start
deliberately, then set it from the length distribution the probe reports.

*Checkpoint:* raw completions printed — not parsed, not scored, **printed**. Token length
distribution and truncation rate. Milliseconds per rollout.

*Ask:* does the output look like the behaviour the task needs, or like something else?

### 3. Verifier — `verifier.py`

Ground truth. Given an action and an example, is it correct?

Prefer parsing to executing. If the action is an expression, walk an AST rather than
calling `eval`; if it is code, a subprocess sandbox costs seconds per step and will
dominate everything. Return a **structured verdict**, not a bool — parsed? well-formed?
correct? the value it produced? the error? — because the reward function needs those tiers
and so does every debugging session.

*Checkpoint:* **the known-good-answer gate.** Every reference solution verifies as correct.
Anything below 100% is a broken harness and no downstream number means anything until it
is 100%. Plus: malformed input, injection attempts, and edge cases score safely rather
than crashing or executing.

### 4. Model — `model.py`

Load the policy, apply whatever adaptation the config asks for, generate. Thin.

Read the device and precision from config rather than hard-coding either. The subset of
precisions, attention backends and quantized optimizers available differs across
accelerators, so a hard-coded choice is the first thing to break when the project moves.

*Checkpoint:* loads inside the memory budget on the target hardware, generates, and the
memory high-water mark is recorded. Any adaptation loads and demonstrably changes the
output — an adapter that silently fails to attach produces a run that trains nothing.

### 5. Eval — `eval.py`

The held-out task metric. Greedy, so the number is a property of the policy rather than of
the sampling seed. Same prompt and same cap as training, or the comparison is invalid.

*Checkpoint:* **the untrained baseline, recorded in `journal/experiments.md`.** Every later claim
is a comparison against this number, so it is not optional and it is not "roughly".

*Ask:* is the baseline in a band where improvement is measurable? A baseline at 0% has
nothing to reinforce; at 95% there is no headroom. Say which, and propose the dial.

### 6. Reward function — `reward.py`

Verdict to scalar. Last, because it is the component you will tune most, and tuning it
requires everything above to be measurable first.

**Reward shapes are named config, never constants in code.** The set from the intake
becomes a table of named shapes and one active choice, so comparing them is a sweep axis
rather than a code edit.

The design tension to state explicitly in the config comments: partial credit buys gradient
availability and costs proxy fidelity. Too little and whole groups score uniformly zero,
so a group-based algorithm has no gradient. Too much and the policy climbs the partial
hill instead of the one that leads to solving. Where that balance sits is empirical per
task, which is exactly why it is a swept setting.

*Checkpoint:* known-good scores maximum, garbage scores zero, the tiers are ordered under
**every** shape, and the most obvious reward hack you can think of does not pay.

*Ask:* what is the premium for the hard behaviour over the easy near-miss? If solving pays
1.0 and a near-miss pays 0.8, gradient ascent has little reason to attempt the hard thing.

---

## Verification — the ladder

Components passing their own tests is not the same as the environment working. Climb all
seven rungs; see [`references/GATES.md`](references/GATES.md) for how to read each.

| | Gate | Fails when |
|---|---|---|
| **L0** | Unit tests per component | a component's behaviour changed |
| **L1** | Integration tests per seam | an interface between two moved |
| **L2** | **Known-good answers score maximum** | the harness is broken |
| **L3** | **Raw completions read by a human** | the model is doing something nobody predicted |
| **L4** | **Probe** — reward spread, gradient availability, timing | the configuration is untrainable |
| **L5** | **Smoke run** — N steps, finite `grad_norm`, no OOM | the loop is not alive |
| **L6** | Baseline recorded | there is nothing to compare against |

**L2 and L3 are the ones that get skipped and the ones that catch real bugs.** Both are
cheap. Neither can be replaced by an aggregate metric, because the failures they catch are
invisible in aggregates by construction — a harness that scores every correct answer zero
produces a perfectly plausible mean reward.

L4 is the go/no-go before spending real compute. A probe that shows a solve rate of zero,
or every group scoring identically, means training cannot work and no learning rate will
fix it.

---

## Tracking

Four files in `journal/`, and they are not interchangeable. See
[`ml_logging`](../ml_logging/SKILL.md) for run naming, config snapshots and the metric
vocabulary; see [`notes`](../notes/SKILL.md) for how they divide.

- **`journal/experiments.md`** — the run log and the hyperparameter tables. Below.
- **`journal/notes.md`** — what results mean, open questions, and predictions written
  *before* the run that tests them.
- **`journal/prompts.md`** — every prompt style considered, in full. Below.
- **`journal/learnings.md`** — traps that cost time, so they cost it once.

They live in one directory because they are read together and cross-reference constantly.
`PLAN.md` stays at the root — it is the entry document, not a record. `ml_logging` places
`journal/experiments.md` in the same directory, so there is one location and no override.

Timestamp every entry to the **minute**, not the day. A day-resolution log cannot
reconstruct which config produced which number when three runs happened in an afternoon.
**This applies to table rows too, not only prose entries** — every run row carries a
`started` column and every block header states when it opened and when it was last added
to. A rule that only reaches the paragraphs leaves the run log, which is the part actually
compared, undated.

### `journal/prompts.md`

The prompt is routinely the largest single lever on an RL task and the least likely thing
to be written down — measured at **3x the task metric** on one project, for free, with no
training. It earns a file.

Code holds only the *active* styles. This holds every style considered:

```markdown
## `search` — active

**2026-08-03 13:41 · chosen**

> Work this out by trial and error. Try a combination, compute what it gives, and if that
> is not the target try a different one. Keep going until you find one that works.

**Trying to elicit:** explicit enumerate-evaluate-backtrack, because the task is a search.
**Measured:** solve rate 4.1% -> 12.5% untrained. Mean completion 182 -> 650 tokens.
**Cost:** ~3.5x the tokens, which is ~3.5x the step time. Worth it.

## `terse` — rejected, kept for the record

**2026-08-03 13:41 · superseded by `search`**

> Think briefly, then end your reply with the expression alone in a fenced block.

**Why it lost:** "think briefly" forbids the one behaviour the task requires. Its *mean
reward* was the highest of any style (0.365 vs 0.255) — selecting on reward would have kept
it. See [`learnings.md`](learnings.md).
```

Three rules make it worth keeping:

- **Full text, verbatim.** A paraphrase cannot be diffed against the next version, and
  prompt failures are usually a single word.
- **A rejected prompt keeps its entry after it is deleted from code.** "We tried that and
  it was worse" is exactly what a later session cannot reconstruct from a diff.
- **Record what it cost, not just what it scored.** A prompt that buys 3x the metric for 4x
  the step time is a different decision from one that buys it for free.

### The hyperparameter tables

Three kinds of setting, and conflating them is what makes a tuning log unreadable:

| Kind | What it is | Example |
|---|---|---|
| **Frozen control** | held constant on purpose. Changing one **invalidates every earlier row** | model, quantization, adapter rank, prompt style, reward shape, eval protocol |
| **Axis** | what you are actually searching | learning rate, prompts/step, k, cap, temperature |
| **Observed** | not set by anyone — a *consequence* of the two above | step time, peak memory, dead-group fraction, truncation rate, mean length |

So `journal/experiments.md` is organised as **one block per frozen-control set, and inside
it a table searching the axes.** A block is a self-contained question: *given this setup,
what are the best axis values?* Rows inside a block are comparable to each other and to
nothing outside it.

**When a frozen control changes, start a new block.** Do not append to the old one. This is
the whole point — it is what stops the failure where a baseline silently moves and every
earlier number quietly stops meaning what it used to.

```markdown
## Block 2 — prompt:search · shape:solve_dominant

**Opened 2026-08-03 14:02.** Last row 2026-08-03 17:41.
**Frozen:** qwen-3b · bf16 · LoRA r=16 · prompt `search` · reward `solve_dominant`
**Eval:** greedy, cap 1024, 200 held-out problems, noise floor ±0.01
**Baseline under these controls:** 0.115
**Changed from block 1:** prompt terse -> search, shape graded -> solve_dominant.
Block 1 numbers are not comparable to these.

### Axis search

| started | run | lr | prompts/step | k | cap | temp | **task metric** | step s | dead grp | trunc | note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 08-03 14:02 | `brave-mantis` | 5e-5 | 8 | 8 | 1024 | 1.0 | **0.140** | 16 | 0.02 | 0.04 | first real movement |
| 08-03 15:19 | `calm-heron`   | 1e-4 | 8 | 8 | 1024 | 1.0 | **0.155** | 16 | 0.03 | 0.05 | best so far |
| 08-03 17:41 | `witty-otter`  | 5e-5 | 4 | 8 | 1024 | 1.0 | 0.121 | 9 | 0.02 | 0.04 | halving batch costs ~0.02 |

### Coverage within this block

| axis | tried | best | untested |
|---|---|---|---|
| learning rate | 5e-5, 1e-4 | 1e-4 | 2e-4 — is it still climbing? |
| prompts/step | 4, 8 | 8 | 16 |
| k | 8 | — | 4, 16 |
| cap | 1024 | — | 768 (cheaper) |
```

Three rules make the structure hold:

- **The block header states its own baseline**, measured under its own frozen controls. A
  baseline from a different block is not a baseline.
- **An axis with one value tried is untested, not settled.** The `untested` column is what
  stops a default from being mistaken for a decision.
- **Observed columns sit beside the metric, never in the coverage table.** They are outputs.
  They explain a ranking; they are not something you search over.

Which axis fields are non-negotiable on a run row, and why they are duplicated from the
config snapshot:

| Field | Why it is on the row |
|---|---|
| **started, to the minute** | the run name already encodes it, and nobody decodes a name. A column is what makes "which of these ran after the fix" and "how long was the gap" answerable at a glance, and it is what lets a block state when it opened and when it was last touched |
| learning rate | the axis you will sweep most |
| **prompts per gradient step** | the *derived* batch number, not per-device x accumulation — the config's figure is routinely several times larger than the real one |
| rollouts per prompt (k) | trades solves-per-group against number of groups |
| **generation cap** | sets step time, and gates truncation — a cap change silently moves the reward |
| **temperature** | exploration; interacts with k, and a run at a different temperature is a different experiment |

Adapter rank, reward shape and prompt style live in the **block header**, not the row — they
are frozen controls, and a run that changed one belongs in a different block.

The config snapshot in `output/configs/` holds all of this and more. The row exists anyway,
because a table you can read is what makes you *notice* two runs differ; a snapshot you have
to `diff` is what you reach for once you already suspect it.

**Queue** — what is next, the hypothesis it tests, **what would falsify it**, and the cost.
A queued experiment with no falsifier is a chore, not an experiment.

### After every experiment

Not at the end of the day. Append the row, then write the read of it in `journal/notes.md` —
what moved, what did not, and whether it confirms or kills the prediction that was written
before it ran. A result that contradicts the prediction is the most valuable output
available and it is the one most easily rationalised away an hour later.

**Record failures with the same weight as successes.** A run that closes a door
permanently is worth more than one that nudges a number.

---

## Style

Full rules in [`coding-standards`](../coding-standards/SKILL.md); this is what bites in RL
code specifically.

- **Every module runs standalone.** A `__main__` at the bottom that exercises the module on
  real input and prints what it produced. In RL this is the fastest way to see what a
  component actually does, and unlike a comment it cannot go stale.
- **All tunables in YAML.** Model, dataset, rollout count, temperature, caps, reward shapes,
  algorithm. If it is a number someone will want to change, it is config. If it is a
  literal in a branch, it is a bug waiting to be untunable.
- **`data/` in, `output/` out.** Every artifact a run produces — checkpoints, metrics,
  config snapshots, eval results, sweep tables — lands under `output/` and nowhere else, so
  the whole directory is safe to gitignore, delete and regenerate. This is the concrete
  directory name; [`ml_logging`](../ml_logging/SKILL.md) governs what goes *inside* it.
- **One override mechanism** — `--set a.b=value` by dotted path, and it must **raise** on a
  key that does not exist. Note that `yaml.safe_load("5e-5")` returns the *string*
  `"5e-5"`; parse through YAML then fall back to `int()`/`float()`.
- **Fail fast, and errors carry the offending value.** Never wrap something you do not
  understand in `try`/`except` — in RL the silent-wrong-answer failure mode costs a whole
  run, and the traceback is the fastest description of the problem you will get.
- **Flat over abstract.** No trainer base classes, no reward registries, no strategy
  objects. The algorithm choice is a branch in one place, and it stays a branch until there
  is a second real reason.
- **Separate computation from effects.** Reward and verifier are pure functions of their
  inputs — that is what makes them unit-testable without an accelerator, and it is what
  lets the whole environment be validated on a laptop before any of it is trained.

---

## Done when

A human who has not seen the project can read the whole environment in a sitting, and:

- every component runs standalone and has passing unit tests; every seam has an
  integration test
- **known-good answers score maximum reward** — the harness gate is green
- raw completions have been read by a human and look like the task
- the probe reports reward spread, gradient availability, token lengths, truncation rate
  and ms/rollout, and a decision was made on that evidence
- a smoke run completes N steps with finite `grad_norm` and no OOM, and **measured** step
  time projects one experiment inside the budget from the intake
- the untrained baseline is recorded in `journal/experiments.md` with its config snapshot
- every tunable is in YAML, `journal/experiments.md` has a frozen-control block with its
  axis-search and coverage tables, and the queue has at least one experiment with a stated
  falsifier

**Then stop.** Tuning is [`tune-loop`](../tune-loop/SKILL.md), and it is the next session's
work.
