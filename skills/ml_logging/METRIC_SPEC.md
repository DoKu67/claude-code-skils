# Metric spec

The vocabulary. Every metric logged by any run in any repo comes from this file.
A name that is not here gets added here first, so the next project uses the same
one.

Namespaces are `/`-separated. `val` is always the held-out split used for
selection during training; `test` is touched once, at the end. Never `eval` —
map HF's `eval/*` onto `val/*` at the boundary.

## Core — every run, every task

Declared at init and logged for the life of the run.

| metric | notes |
|---|---|
| `train/loss` | the optimized objective, post-reduction |
| `val/loss` | same objective on the held-out split |
| `test/loss` | logged once, at the end |
| `train/lr` | actual scheduled value, not the configured peak |
| `train/grad_norm` | pre-clipping |
| `train/step_time_s` | wall-clock per optimizer step |
| `train/tokens_per_s` | throughput; `samples_per_s` where tokens are meaningless |
| `sys/gpu_mem_gb` | peak allocated since last log |
| `sys/gpu_util` | 0–1 |
| `progress/global_step` | **the x-axis.** Optimizer steps. Strictly monotonic |
| `progress/epoch` | fractional |
| `progress/tokens_seen` | cumulative |

## Reproducibility — set once at init, into `wandb.config` and `summary.json`

`git/sha`, `git/branch`, `git/dirty` (upload the diff as an artifact when
dirty), `run/seed`, `run/argv`, `run/status`, `env/python`, `env/torch`,
`env/cuda`, `env/transformers`, `env/trl`, `env/peft`, `env/gpu_name`,
`env/gpu_count`.

`run/status` ∈ `completed | crashed | oom | interrupted`, set in a `finally`.

## Task packs

Layered onto core, selected by the project's task. Log the whole pack or none of
it — a partially-populated pack is what makes two runs incomparable.

### `lm` / `sft` — language modeling, supervised fine-tuning

`train/ppl`, `val/ppl`, `train/entropy`, `train/token_acc`

Perplexity is logged explicitly rather than derived at read time, so it survives
a change in the loss reduction.

### `preference` — DPO, KTO, ORPO, CPO, IPO

`rewards/chosen`, `rewards/rejected`, `rewards/margin`, `rewards/accuracies`,
`logps/chosen`, `logps/rejected`, `kl/ref_mean`

These are TRL's own names, kept verbatim so TRL trainers need no mapping.
`rewards/accuracies` — the fraction where chosen outscores rejected — is the one
that tells you whether the run is learning at all.

### `rl` — policy gradient, any flavor

| metric | notes |
|---|---|
| `reward/mean` | primary curve |
| `reward/std` | |
| `reward/max`, `reward/min` | |
| `rollout/ep_len_mean` | |
| `rollout/success_rate` | where the task has a success criterion |
| `policy/entropy` | collapse detector |
| `policy/approx_kl` | per-update KL from the pre-update policy |
| `policy/clip_frac` | fraction of ratios hitting the clip bound |
| `kl/ref_mean` | KL from the frozen reference; the drift signal |
| `value/loss`, `value/explained_var` | where a critic exists |
| `advantage/mean`, `advantage/std` | |
| `progress/env_steps`, `progress/episodes` | the other two clocks |

### `grpo` — adds to `rl`

`reward/group_std` — the within-group reward spread. When it goes to zero the
advantages vanish and the run is silently doing nothing; nothing else in the
pack catches this.

Drop `value/*` — GRPO has no critic.

### `rlvr` — verifiable rewards, adds to `rl`

`reward/verifier_pass_rate`, `reward/format_pass_rate`, `reward/length_penalty`

Decompose the scalar reward into its components. A flat `reward/mean` cannot
distinguish a policy that learned the task from one that learned the output
format.

### `classification`

`val/acc`, `val/f1`, `val/precision`, `val/recall`, `val/auroc`, plus a
confusion matrix as an artifact at eval time.

### `reconstruction` — hypernets, adapter/weight prediction

`recon/mse`, `recon/cos_sim`, `recon/rel_err`, and `generalization/*` mirroring
the same three on held-out targets.

## Trainer name mapping

What HF/TRL emit, and what it maps to. When `wandb.init()` is called first per
the skill, these arrive on the existing run automatically — rename in a
`TrainerCallback` rather than logging both.

| emitted | maps to |
|---|---|
| `train/loss` | `train/loss` — unchanged |
| `eval/loss` | `val/loss` |
| `eval/runtime`, `eval/samples_per_second` | drop |
| `train/learning_rate` | `train/lr` |
| `train/grad_norm` | `train/grad_norm` — unchanged |
| `train/epoch` | `progress/epoch` |
| `train/global_step` | `progress/global_step` |
| `rewards/*` (TRL preference) | unchanged — the `preference` pack is TRL's names |
| `objective/kl` (TRL online) | `kl/ref_mean` |
| `completions/mean_length` | `rollout/ep_len_mean` |

## Adding to this file

A new metric earns a row when a second project needs it. Until then it is a
project-local name and stays out. When adding: state what it detects, not what
it computes — `reward/group_std` is here because it catches advantage collapse,
and that sentence is why the next person logs it.
