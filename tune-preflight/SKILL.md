---
name: tune-preflight
description: The gate before launching any training or evaluation run — estimate peak memory, project wall clock against the budget, and return a green/amber/red verdict with a mitigation ladder. Use before every fine-tune, sweep cell, eval or rollout job; whenever a batch size, sequence length, model, adapter, precision or rollout count changes; whenever the user worries about OOM, cost or a run that will not finish overnight; and whenever a run has already OOM'd and the next attempt needs a reason to be different.
---

# tune-preflight

Two minutes of arithmetic before a launch, against an hour of GPU time and a corrupted
grid after one. **The estimate's job is not to be exact — it is to catch the 2× error**,
which is the size of mistake that OOMs at step 3 or turns a 40-minute run into an
overnight one.

Run it before **every** launch, including the one that is "the same as last time but with
a bigger batch". That is the run that OOMs.

Called by [`tune-loop`](../tune-loop/SKILL.md) at step 3 of the iteration; escalates via
[`escalate`](../escalate/SKILL.md) on red.

---

## Four questions

| Question | Answer is | Fails when |
|---|---|---|
| **Does it fit?** | peak memory as a fraction of the device | > 90% → red |
| **How long?** | measured step time × steps + eval | over the block's budget |
| **What does it cost?** | GPU-hours, against what remains of the budget | over what was agreed at intake |
| **What breaks first?** | the constraint that binds — memory, time, or data | you cannot name it |

Answer all four in writing before the launch. The fourth is the one that makes the next
preflight cheap: once you know which constraint binds, you know which knob the next
change must respect.

---

## Memory

Add four terms. Any one of them can dominate, which is why guessing from experience with
a different setup is unreliable.

### 1. Resident model state

Per **trainable** parameter, for the common configurations:

| Setup | Bytes/param | What is in it |
|---|---|---|
| Full FT, bf16 + Adam, fp32 master | ~16 | weights 2 + grad 2 + master 4 + moments 8 |
| Full FT, bf16 + Adam, bf16 states | ~10 | weights 2 + grad 2 + moments 4 (+ slack) |
| Full FT, 8-bit optimizer | ~8 | moments quantised to 1 byte each |
| SGD + momentum, bf16 | ~6 | no second moment |
| **LoRA / adapters** | base ~2 (bf16), ~1 (int8), ~0.5 (nf4) + ~16 × *adapter* params | base weights are frozen: no grads, no moments |

The LoRA row is why adapters change the memory picture qualitatively rather than
proportionally: the 16 bytes/param term applies to a rank-16 adapter's parameters, which
are typically well under 1% of the model.

### 2. Activations

Order of magnitude, not a formula to trust:

```
activations ≈ batch × seq_len × hidden × layers × k bytes
```

with `k` roughly 10–20 without gradient checkpointing and near 1–2 with it. This is the
term that scales with **batch × sequence length**, so it is almost always the one that
moved when a configuration that fit last week does not fit now.

### 3. Inference / rollout cache

Any run that generates — RL rollouts, generative eval, a judge — pays a KV cache:

```
kv ≈ 2 × layers × kv_heads × head_dim × (prompt + generated) × concurrent_sequences × dtype_bytes
```

For a group-based RL algorithm, `concurrent_sequences` is **prompts per step × k**, not
prompts per step. This is the single most common miss in an RL preflight.

If generation runs in a separate serving engine, its pre-allocated cache is subtracted
from the device before training gets any — count it as a fixed cost, not a variable one.

### 4. Headroom

**Leave 15% unaccounted.** Fragmentation, the allocator's caching, a transient peak
during optimizer construction, the eval pass that runs at a different batch size. A plan
that fits in 100% of the device does not fit.

### The verdict

| Verdict | Estimated peak | Action |
|---|---|---|
| **Green** | < 70% of device | Launch |
| **Amber** | 70–90% | Launch **only** with a free-rung mitigation applied, or after measuring the real peak on a short run |
| **Red** | > 90%, or any term you could not estimate | **Do not launch.** [`escalate`](../escalate/SKILL.md) |

Red on an unestimatable term is deliberate: an unknown term is not a small term. Say which
one you could not estimate and what measurement would resolve it — usually a 10-step run
at the smallest batch, which is cheap and turns the unknown into a coefficient.

---

## The mitigation ladder

Ordered by what it costs you. **The line in the middle matters more than the ordering**:
above it, the experiment is unchanged and the block survives; below it, you have changed a
frozen control and every earlier row in the block is no longer comparable.

| Rung | Buys | Costs | Block |
|---|---|---|---|
| Per-device batch ↓, grad accum ↑ | Large activation cut | ~nothing, if **effective batch is held exactly** | survives |
| Gradient checkpointing on | ~5–10× activations | ~20–30% step time | survives |
| 8-bit optimizer states | ~4 bytes/param | small numerical risk | survives |
| Eval/generation batch ↓ | The peak, if eval is the peak | wall clock only | survives |
| — | — | — | — |
| Sequence length or generation cap ↓ | Activations and KV, linearly | **truncates data or rollouts** | **new block** |
| Precision or quantisation change | Weights, proportionally | accuracy, and comparability | **new block** |
| LoRA rank ↓, or full FT → adapter | Most of the optimizer state | capacity | **new block** |
| CPU / disk offload | Almost anything | 2–10× step time | survives, but the budget will not |
| Smaller base model | Everything | the experiment you were running | **new block** |

**Effective batch is held exactly, or the top rung is not free.** Halving per-device batch
and doubling accumulation keeps it; halving per-device batch alone changes the experiment
while looking like an infrastructure fix, and it is the most common way a tuning grid
quietly acquires a confounded row.

When only a below-the-line rung will fit, that is not a preflight decision. It changes what
is being measured, so it goes to [`escalate`](../escalate/SKILL.md) with the two options
priced.

---

## Time and cost

```
projected = measured_step_time × steps + eval_time × eval_count + startup
```

**Measured, from the smoke run — never assumed.** A step time carried over from a different
sequence length, batch size or generation cap is not an estimate, it is a wish.

Then check against the block's fixed experiment budget from
[`tune-loop`](../tune-loop/SKILL.md). If the projection exceeds it, cut **steps**, not the
comparability: a run that trains for fewer steps than its block declares is not a row in
that block.

Two sanity checks worth doing while the arithmetic is out:

- **Is the whole remaining queue affordable?** Projecting one run is not the same as
  projecting the six the queue holds. When the queue exceeds the budget, say so now — that
  is a planning conversation, not a mid-sweep surprise.
- **Does anything unbounded grow?** Checkpoints per run × runs against free disk. A sweep
  that fills the disk at cell 9 fails in a way that looks like a training bug.

---

## During and after

**Log peak memory as an observed column** on every run. It is what turns the next
preflight from arithmetic into a lookup, and it is the number that shows a configuration
creeping toward the ceiling before it hits it.

**A memory figure that climbs steadily across steps is a leak, not a large model.** Stop
it — see [`run-triage`](../run-triage/SKILL.md). No preflight predicts an unbounded term.

**An OOM is a recorded result.** The row keeps the configuration, the step it died at, and
the peak reached. It marks the boundary of the feasible region, which is information the
grid needs and the next preflight uses directly.

**A second OOM in the same block, after a mitigation, escalates.** Two failures mean the
estimate is wrong in a way another guess will not fix.

---

## Out of scope

Cluster scheduling, queueing and multi-node topology. Kernel-level or throughput
optimization — this skill decides whether to launch, not how to make it fast; that is
stage 3 of [`mvp`](../mvp/SKILL.md).

---

## Done when

Peak memory is estimated term by term with 15% headroom and stated as a fraction of the
device; wall clock is projected from a **measured** step time and checked against the
block's budget; the binding constraint is named; the verdict is green, amber or red with
any mitigation identified as block-surviving or block-breaking; and red or a
block-breaking mitigation has gone to [`escalate`](../escalate/SKILL.md) rather than being
applied quietly.
