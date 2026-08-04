---
name: run-triage
description: Decide whether a training run is healthy, should be killed, or is revealing a bug rather than a bad hyperparameter — from its curves, its logs and its raw outputs. Use while a fine-tune is running and something looks wrong, after any crash or OOM, when loss goes NaN or flat or spikes, when reward climbs but the held-out metric does not, when a run finishes and the result is ambiguous, and before recording any row whose number is surprising.
---

# run-triage

Every run gets a verdict, and there are only three: **healthy**, **kill**, or **bug**.

The distinction that matters is the last one. A bad hyperparameter produces a run that is
recoverable by changing the hyperparameter; a bug produces a run that no value of any axis
will fix. Tuning through a bug is the most expensive thing this loop can do — it burns the
budget and fills the grid with rows that measure the bug, and it ends with a coverage table
that says the search was thorough.

**Triage early.** Inside the first 10–20% of the budget, not at the end. Most doomed runs
are diagnosable in the first minutes, and everything after that point is spent proving
something already known.

Called by [`tune-loop`](../tune-loop/SKILL.md) at step 5. Traps found here go in
`learnings.md` per [`notes`](../notes/SKILL.md), with the **tell** — what distinguished
this failure from a normal one — because the tell is the transferable part and the fix
usually is not.

---

## Three checks that catch silent failures

Cheap, and between them they catch most of the failures that produce a plausible-looking
curve and a meaningless number. Run them once per block, not once per run.

1. **Read raw model outputs.** Not parsed, not scored — printed. A metric cannot show you
   that the model is answering in the wrong language, emitting the prompt back, or
   producing an empty string that the parser scores as a clean zero.
2. **Confirm a known-good input scores maximum** end to end through the live pipeline. If
   the harness cannot recognise a correct answer, no number downstream means anything.
3. **Print the trainable parameter count** and check it against what you intended. An
   adapter that silently failed to attach trains nothing, and the loss curve looks
   entirely ordinary.

---

## Signatures

Symptom, then the tell that separates it from the neighbouring diagnosis.

### Anything, any regime

| Symptom | Tell | Usually | Verdict |
|---|---|---|---|
| Loss `NaN`/`inf` | `grad_norm` spikes 1–2 steps before | Learning rate above the stability edge; fp16 overflow | **Kill** |
| `grad_norm` growing without bound | Loss still finite but rising | Too-high lr, missing or too-loose clipping | **Kill** |
| Loss spike then recovery | Returns to trend within ~20 steps | A bad batch; benign if isolated | Healthy — note it |
| Loss exactly `0.0`, or flat from step 0 | Never moves at all | Everything masked out, or nothing trainable | **Bug** |
| Loss falls, held-out metric does not move | The gap opens from the first eval | Train/eval mismatch — different template, tokenizer or parser | **Bug** |
| Held-out better than train | Persists across evals | Contamination, or eval is easier than it should be | **Bug** |
| Memory climbing steadily across steps | Peak rises monotonically, no plateau | A leak — tensors retained in a list, graph kept alive | **Kill** |
| Throughput collapsing over time | Step time rises, memory flat | Fragmentation, growing sequence lengths, host bottleneck | Investigate |
| Metric sits at chance | Exactly at the chance level, not near it | Labels shuffled, or predictions misaligned by one | **Bug** |
| Crash / OOM | — | See [`tune-preflight`](../tune-preflight/SKILL.md) | Record the row |

### Supervised and SFT

| Symptom | Tell | Usually | Verdict |
|---|---|---|---|
| Val loss rises while train falls | Turns within the first epoch on small data | Overfitting; SFT overfits far faster than people expect | **Kill** — early stop, fewer epochs |
| Loss suspiciously low from step 1 | Below the entropy the task allows | Loss computed over prompt tokens too — masking bug | **Bug** |
| Outputs ignore the chat format | Model emits raw continuations | Template mismatch between training and inference | **Bug** |
| Loss plateaus high, immovably | Unchanged across a decade of lr | Data is not learnable as formatted; or the sequence is truncating the answer | Investigate |

### Preference (DPO / KTO / ORPO) and reward models

| Symptom | Tell | Usually | Verdict |
|---|---|---|---|
| Both chosen and rejected logprobs collapsing | Margin grows while both fall | β too low — the policy is running from the reference, not toward preference | **Kill** |
| Margin ~0, accuracy ~50% | No separation from step 1 | Pairs are not actually distinguishable, or chosen/rejected are swapped | **Bug** |
| Reward model accuracy near 100% on train | Held-out far lower | Memorising annotator artefacts — length, formatting | Investigate |
| Outputs get longer every eval | Length rises with reward | Length is the shortcut the preference signal is paying for | **Bug** in the signal |

### Policy RL (GRPO / PPO / RLOO / RLVR)

| Symptom | Tell | Usually | Verdict |
|---|---|---|---|
| Reward flat at zero | Solve rate 0 in the probe too | Task is out of reach at this model/prompt — no lr fixes it | **Bug** in the setup |
| Reward flat, nonzero | **Dead-group fraction high** — no spread within a group | Nothing to learn from: group-relative advantage is zero | **Kill** — reward shape or temperature |
| Entropy collapsing toward zero | Falls order-of-magnitude below its healthy value | Policy collapsed to one output; often a too-high lr or too-low KL | **Kill** |
| Entropy exploding | Far above the healthy band | Divergence in progress; the reward is being ignored | **Kill** |
| KL to reference climbing without bound | Rises while task metric falls | KL coefficient too low | **Kill** |
| **Reward up, held-out task metric flat or down** | The two curves separate and stay separated | **Reward hacking** | **Stop and [`escalate`](../escalate/SKILL.md)** |
| Truncation rate high | Rewards correlate with hitting the cap | Generation cap is cutting answers off mid-solution | Investigate — cap is a frozen control |
| PPO value loss not falling | Explained variance near zero | Value head is not learning; advantages are noise | **Kill** |

---

## Kill criteria

Kill immediately, without waiting for the run to finish, on any of: `NaN`/`inf` loss,
unbounded `grad_norm`, entropy collapse, monotonically climbing memory, or throughput
collapse. Nothing after that point is data.

Otherwise let it finish. A merely disappointing run is a legitimate row and its number is
worth having — the grid needs the shape of the whole region, not only its peak.

---

## What the verdict implies

| Verdict | Next |
|---|---|
| **Healthy** | Record the row. Continue the loop |
| **Kill — instability** | The axis has an upper edge and you found it. Back off toward the last stable value — **halve, do not restore the default**; the edge is information and it belongs in the coverage table |
| **Kill — configuration** | Change the thing the tell named, not the learning rate. A dead-group problem is a reward or temperature problem |
| **Bug** | **Stop tuning.** Fix it, then re-measure the baseline: every row taken since the bug entered is suspect, and rows that predate it may be in a different block now |
| **Same signature twice** after a fix attempt | [`escalate`](../escalate/SKILL.md) |

**When a bug is fixed, say explicitly which earlier rows survive it.** That judgement is
cheap now and impossible in three weeks, and a grid that silently mixes pre- and post-fix
rows is worse than one that is missing them.

---

## Out of scope

Performance profiling and throughput optimization. Root-causing library internals beyond
identifying that the failure is a bug — that is ordinary debugging, and
[`coding-standards`](../coding-standards/SKILL.md) governs the fix.

---

## Done when

The run carries one of the three verdicts; the verdict names the **tell** it was read
from, not just the symptom; a kill states which axis edge it found and what the next value
should be; a bug has stopped the loop and named which earlier rows survive it; suspected
reward hacking has stopped everything and gone to [`escalate`](../escalate/SKILL.md); and
anything that cost real time is in `learnings.md` with its tell.
