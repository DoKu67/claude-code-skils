---
name: hparam-priors
description: Which hyperparameter to search first, what range to search it over, what it is coupled with, and what its failure looks like — per regime: supervised learning, SFT, preference methods (DPO/KTO/ORPO) and reward models, and policy RL (GRPO/PPO/RLOO/RLVR). Use when choosing the next axis to tune, when a starting value is needed for a knob nobody has set deliberately, when deciding whether two settings must move together, and when a result suggests a knob is at its edge. Reference only — it does not run the search.
---

# hparam-priors

**Search order is worth more than search range.** Most tuning budgets are spent on axes
that were never going to move the number, while the one that would have was left at a
default that came from someone else's project.

This skill is reference. The loop that uses it is [`tune-loop`](../tune-loop/SKILL.md);
the gate that decides whether a value is launchable is
[`tune-preflight`](../tune-preflight/SKILL.md).

Read the file for the regime in play:

| File | Regime |
|---|---|
| [`references/SUPERVISED.md`](references/SUPERVISED.md) | Ordinary supervised training, from scratch or fine-tuned |
| [`references/SFT.md`](references/SFT.md) | Instruction / chat SFT, full or adapter |
| [`references/PREFERENCE.md`](references/PREFERENCE.md) | DPO, KTO, ORPO, and reward-model training |
| [`references/POLICY_RL.md`](references/POLICY_RL.md) | GRPO, PPO, RLOO, RLVR |

**Every number in those files is a starting point, not a recommendation.** They exist so a
knob is set deliberately rather than inherited, and so a search has somewhere to begin.
The measurement supersedes them immediately.

---

## Rules that hold across every regime

**Search learning rate on a log scale, and coarsely first.** Half-decade steps — 1e-5,
3e-5, 1e-4 — before anything finer. A linear sweep of a learning rate is a sweep of one
value with extra steps, and fine-grained search below the noise floor is not search.

**The learning rate is coupled to the batch size.** Changing batch size without changing
lr is a different experiment from either change alone. Hold effective batch fixed while
searching lr, then search batch separately, or accept that you are searching a diagonal.

**Two settings are coupled when the best value of one depends on the other.** Those may
move together *when the coupling is the hypothesis* — see the exceptions in
[`tune-loop`](../tune-loop/SKILL.md). Everything else moves alone.

**Prefer the knob whose failure mode you have not ruled out.** If you cannot say what
would go wrong at this knob's current value, searching it is unlikely to pay. The
per-regime tables name the failure for each knob so that question has an answer.

**A default is untested, not settled.** A knob nobody chose is an axis with one value
tried, and it belongs in the coverage table's `untested` column exactly like any other.

**Non-hyperparameter levers usually beat hyperparameters.** Prompt, data quality, loss
masking, reward shape and eval protocol routinely move a metric further than any learning
rate, and several are free. Where a regime has one, its file names it. If one of those is
unexamined, tuning is premature.

---

## Reading a regime file

Each file is a priority-ordered table with the same columns:

| Column | Means |
|---|---|
| **Knob** | The setting |
| **Why here** | What earns it this rank |
| **Start** | A deliberate starting value, not a recommendation |
| **Search** | The range and the step size worth trying |
| **Coupled with** | What must be held fixed, or moved with it |
| **Failure tell** | What it looks like when this knob is wrong — cross-references [`run-triage`](../run-triage/SKILL.md) |

Below the table, each file carries two lists: **do not tune** (settings that are frozen
controls or that have no useful search space) and **check before tuning** (the free levers
that beat hyperparameters in that regime).

---

## Out of scope

The mechanics of running a search, the noise floor, and the block structure — all
[`tune-loop`](../tune-loop/SKILL.md). Anything model- or library-specific beyond the knob
itself: this file names `beta`, not what the argument is called in a given trainer.
