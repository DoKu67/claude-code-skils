---
name: sft-env-mvp
description: Scaffold a minimal, readable fine-tuning setup for supervised learning, SFT, or preference methods (DPO/KTO/ORPO, reward models) — data, split, chat template, loss masking, eval and baseline — and prove it works before any hyperparameter is tuned. Use when starting a supervised or SFT project from scratch, when the user asks to "fine-tune this model on this data", when a training script exists but nobody has checked what the model actually receives, and whenever a dataset, model, template and objective need turning into something a human can read and start tuning. Covers zero to a first fine-tune; it does not tune training itself. Policy RL is out of scope.
---

# sft-env-mvp

Turn a model, a dataset and an objective into a fine-tuning setup a human can **read in
one sitting, edit without archaeology, and start tuning the same day.**

**This skill stops before tuning.** It ends when a smoke run has proven the loop is alive
and the untrained baseline is recorded, so the first real experiment can be launched.
[`tune-loop`](../tune-loop/SKILL.md) takes it from there.

That boundary is deliberate. The failures that waste supervised fine-tuning projects are
almost never hyperparameter failures — they are a template mismatch, a loss mask over the
wrong tokens, a contaminated split, or a metric that was never sensitive to the thing being
optimised. Every one of them produces a healthy-looking loss curve. The point of this skill
is to make them visible before any budget is spent on top of them.

This is [`mvp`](../mvp/SKILL.md) applied to a domain, and the sibling of
[`rl-env-mvp`](../rl-env-mvp/SKILL.md) — read that one instead if the objective is
GRPO, PPO, RLOO or RLVR. Read [`coding-standards`](../coding-standards/SKILL.md) before the
first edit and [`ml_logging`](../ml_logging/SKILL.md) before naming a run or a metric. Where
this skill and `mvp` appear to disagree, `mvp` wins on process and this one wins on what to
measure.

---

## Stage 0 — Intake

Six inputs. Write them down before code.

| Input | What to pin down |
|---|---|
| **Task** | One sentence a stranger could act on. What does the model produce, given what? |
| **Objective** | Supervised loss, SFT, DPO/KTO/ORPO, or a reward model — **defaults to SFT** for instruction data |
| **Model** | Which base, and how it is adapted — full, LoRA, or a head on a frozen trunk |
| **Dataset** | Where from, how many, and how held-out is separated |
| **Metric** | The held-out number the project is *for*, which is not the loss |
| **Budget** | Time per experiment, and total |

### Ask before building

These change the design rather than a parameter, so guessing them is expensive. Ask as one
batch, with a recommendation on each:

1. **What is the held-out metric, and how does it differ from the loss?** If the answer is
   "val loss", the project cannot detect the regime's central failure — an objective
   satisfied without the behaviour improving. Name a task metric or say explicitly that
   there is none.
2. **Where does held-out come from?** It must be structurally incapable of overlapping
   train — a hashed key, a time cut, a distinct source. "Shuffle and slice" is how a
   contaminated split gets written.
3. **Is the base model already instruction-tuned, and whose template does it expect?** This
   decides the formatting work and is the most common source of a silent mismatch.
4. **What hardware?** The memory ceiling decides full-vs-adapter, batch size and sequence
   length simultaneously — see [`tune-preflight`](../tune-preflight/SKILL.md). Put the
   answer in config; never carry it over from another project.
5. **How much data, and how good?** A thousand curated examples beat fifty thousand scraped
   ones, and no hyperparameter closes that gap. If quality is unknown, reading fifty
   examples is the first experiment.

### The rough plan

A `PLAN.md` before code: the six inputs, the decisions and why, the components in build
order with the checkpoint each stops at, and **the one risk most likely to invalidate the
whole thing**. A page, not a specification. It carries a **deferred** list — everything
named at intake that is not on the path to the first fine-tune.

Then a tracked todo list: one task per component, plus the overfit test, the smoke run and
the write-up.

---

## Build order

Five components, each stopping at a checkpoint. **Stop and report at every one.** Build in
this order, because each checkpoint depends on the previous component being trustworthy.

### 1. Data — `data_loader.py` and `data/`

Load, split, and hand back records. `data_loader.py` is the code; `data/` holds the inputs
themselves, so it can be gitignored and regenerated.

*Checkpoint:* counts per split, the **train/held-out overlap count (must be zero)** by the
structural key, the label or response length distribution, and five raw records printed in
full.

*Ask:* is the data what we thought it was? This is where reading fifty examples pays.

### 2. Formatting — `format.py`

Records to model inputs: the chat template, the special tokens, the truncation policy, and
**the loss mask**. This module is the highest-risk code in the project and the smallest.

*Checkpoint — the gate that catches the silent failures.* For three examples, print:

- the fully rendered string, template applied
- the token ids, **decoded back**
- the loss mask alongside the decoded tokens, so a human can see that loss falls on the
  response and not the prompt
- where EOS lands
- the truncation rate across the dataset, not the mean length

*And diff the training template against the eval/inference template, byte for byte.* A
mismatch here produces a model that trained perfectly and behaves as if it did not.

For preference objectives, add: twenty chosen/rejected pairs read by a human to confirm
they are not swapped, and the **mean token length of chosen vs rejected** — if chosen is
consistently longer, length is what will be learned.

### 3. Model — `model.py`

Load the base, apply the adaptation the config asks for, generate. Thin. Device and
precision come from config, never hard-coded.

*Checkpoint:* loads inside the memory budget on the target hardware; the **trainable
parameter count is printed and matches intent**; an adapter demonstrably changes the output.
An adapter that silently failed to attach trains nothing and its loss curve looks ordinary.

### 4. Eval — `eval.py`

The held-out task metric. Fixed decoding — greedy or a fixed seed — so the number is a
property of the model rather than of sampling. Same template and truncation as training, or
the comparison is invalid.

*Checkpoint:* **the untrained baseline, recorded in `journal/experiments.md`** with its
config snapshot. Every later claim is a delta against it.

*Ask:* is the baseline in a band where improvement is measurable? At 0% there is nothing to
build on; at 95% there is no headroom. Say which, and propose the dial.

### 5. Training loop — `train.py`

Last. Whether it is a hand-rolled loop or a trainer from a library, it stays thin: config
in, metrics out per [`ml_logging`](../ml_logging/SKILL.md), checkpoints and eval on a
schedule.

*Checkpoint:* the overfit test and the smoke run, below.

---

## Verification — the ladder

Component tests passing is not the same as the setup working. Seven rungs:

| | Gate | Fails when |
|---|---|---|
| **L0** | Unit tests per component | a component's behaviour changed |
| **L1** | Integration tests per seam | an interface between two moved |
| **L2** | **Rendered examples read by a human** — template, mask, EOS, decoded | the model is being shown something nobody intended |
| **L3** | **Zero-shot outputs read by a human** | the task is misframed, or the template is wrong at inference |
| **L4** | **Overfit one batch** — 8 examples, loss to near zero | the loop cannot learn at all |
| **L5** | **Smoke run** — N steps, finite `grad_norm`, no OOM, one eval completes | the loop is not alive end to end |
| **L6** | Baseline recorded with its config snapshot | there is nothing to compare against |

**L2 and L4 are the ones that get skipped and the ones that catch real bugs.**

L4 deserves its own note: training on eight examples until the loss approaches zero is the
cheapest possible proof that data, mask, model and optimizer are wired together. A loop
that *cannot* overfit eight examples has a bug, and no learning rate will fix it. A loop
that can has ruled out most of the ways the wiring fails. It costs a minute.

L2 and L3 cannot be replaced by an aggregate — a mask over the wrong tokens produces a
perfectly plausible loss curve, which is exactly what makes it expensive.

---

## Tracking

Four files in `journal/`, as [`rl-env-mvp`](../rl-env-mvp/SKILL.md) defines them:
`experiments.md` (the run log and the grid), `notes.md` (what results mean),
`prompts.md` (every prompt or template style considered, in full, including rejected ones),
`learnings.md` (traps that cost time). `PLAN.md` stays at the root.

The grid's structure — frozen controls, axes, observed, one block per control set — belongs
to [`tune-loop`](../tune-loop/SKILL.md) and [`tune-report`](../tune-report/SKILL.md). This
skill's only obligation is to leave the first block's header filled in: frozen controls,
fixed experiment budget, and the baseline from L6.

Timestamp every entry to the **minute** — table rows as well as prose. Every run row carries
a `started` column and every block header states when it opened and when it was last added
to; a rule that only reaches the paragraphs leaves the run log, which is the part actually
compared, undated.

---

## Style

Full rules in [`coding-standards`](../coding-standards/SKILL.md); what bites here
specifically:

- **Every module runs standalone**, with a `__main__` that exercises it on real input and
  prints what it produced. For `format.py` this is the L2 gate, permanently available.
- **All tunables in YAML** — model, data paths, template name, max length, packing,
  objective, adapter config, batch, lr. One override mechanism, `--set a.b=value` by dotted
  path, and it must **raise** on a key that does not exist. Note that
  `yaml.safe_load("5e-5")` returns the *string* `"5e-5"`.
- **`data/` in, `output/` out.** Every artifact a run produces lands under `output/`, so
  the whole directory is safe to gitignore and regenerate.
- **Fail fast, and errors carry the offending value.** Never wrap something you do not
  understand in `try`/`except`; a silent-wrong-answer here costs a whole run.
- **Flat over abstract.** No trainer base classes, no dataset registries. The objective is
  a branch in one place until there is a second real reason.

---

## Out of scope

Policy RL — [`rl-env-mvp`](../rl-env-mvp/SKILL.md). Hyperparameter search —
[`tune-loop`](../tune-loop/SKILL.md). Serving, quantised export, and distillation.

---

## Done when

A human who has not seen the project can read the whole setup in a sitting, and:

- every component runs standalone with passing unit tests; every seam has an integration
  test
- **rendered examples have been read by a human** — template, loss mask, EOS, decoded
  tokens — and the training and inference templates are byte-identical
- train/held-out overlap is zero by a structural key
- zero-shot outputs have been read and look like the task
- **the loop overfits eight examples to near-zero loss**
- a smoke run completes N steps with finite `grad_norm`, no OOM, and one full eval, and the
  **measured** step time projects one experiment inside the intake budget
- the untrained baseline is in `journal/experiments.md` with its config snapshot
- every tunable is in YAML, and the first block header in `journal/experiments.md` names its
  frozen controls and its fixed experiment budget

**Then stop.** Tuning is [`tune-loop`](../tune-loop/SKILL.md), and it is the next session's
work.
