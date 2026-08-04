# Policy RL — GRPO, PPO, RLOO, RLVR

Online policy optimization where rollouts are generated, scored, and turned into a
gradient.

The regime's defining property: **most failures are not tuning failures.** A flat reward is
usually a reward that produces no spread, a task out of the model's reach, or a verifier
that cannot recognise a correct answer — none of which any learning rate fixes. The probe
and gate discipline in [`rl-env-mvp`](../../rl-env-mvp/SKILL.md) exists for exactly this,
and tuning before it passes is wasted budget.

## Priority order

| Knob | Why here | Start | Search | Coupled with | Failure tell |
|---|---|---|---|---|---|
| **Learning rate** | Dominant, and RL's stable range is far below SFT's | 1e-6–5e-6 full FT; 1e-5–1e-4 LoRA | Half-decades, 3 values | batch, KL coefficient | Too high: entropy collapse, or reward climbs then falls off a cliff. Too low: flat reward with healthy spread |
| **Rollouts per prompt (k)** | Group methods have no gradient without within-group spread; this is the knob that buys it | 8 | 4, 8, 16 | temperature; memory | **Dead-group fraction** — groups where every rollout scores identically |
| **Prompts per gradient step** | The real batch number, and routinely several times smaller than the config implies | 8–32 | ×2 / ÷2 | k, lr | Noisy reward curve; run-to-run ranking unstable |
| **KL coefficient** (or the clip that stands in for it) | Sets how far the policy may drift from the reference; the knob that decides whether gains survive | 0.01–0.05 | 0, 0.01, 0.05, 0.1 | lr | Too low: KL climbs without bound, task metric falls while reward rises. Too high: nothing moves |
| **Temperature** | Exploration. Interacts with k, and a run at a different temperature is a different experiment | 1.0 | 0.7, 1.0, 1.2 | k | Low: dead groups. High: rollouts too incoherent to be scored meaningfully |
| **Generation cap** | Sets step time *and* silently moves the reward by truncating solutions | From the probe's length distribution | Set from measurement, then treat as a frozen control | seq len, memory, step time | Truncation rate rising, or reward correlating with hitting the cap |
| **PPO: clip range** | The stability knob once lr is in range | 0.2 | 0.1, 0.2, 0.3 | lr | Clip fraction near 0 (nothing constrains) or near 1 (nothing updates) |
| **PPO: value loss coefficient, GAE λ** | Only once the policy side is stable | 0.5; λ=0.95 | 0.1/0.5/1.0; λ ∈ 0.9–0.99 | lr | Explained variance near zero — advantages are noise |
| **Epochs per batch of rollouts** | More reuse is cheaper and less on-policy | 1 | 1, 2, 4 | clip range | Ratio drifting far from 1 late in the inner loop |
| **Advantage normalisation scope** | Changes what the advantage means; often mistaken for a free choice | Per group | per-group vs per-batch | k | A batch-normalised advantage in a group method removes the group structure |

## Do not tune

- **Base model, prompt, reward shape, verifier, dataset, algorithm, adapter rank, eval
  protocol** — frozen controls. Each starts a new block. Reward shape and prompt especially:
  they are the biggest levers in the regime *and* they invalidate every earlier row.
- **The reward function, in response to a disappointing run.** That is redesign, and it
  needs a new block and a re-measured baseline; drifting the reward inside a block is how a
  tuning log becomes fiction.

## Check before tuning

1. **The probe passed** — reward spread within groups, non-zero solve rate, timings. A
   configuration the probe says is untrainable will not become trainable.
2. **Known-good answers score maximum reward** through the live pipeline.
3. **Dead-group fraction is logged.** It is the metric that most often explains a dead run
   and most often goes unlogged.
4. **A held-out task metric exists that is not the reward.** Without it, reward hacking is
   undetectable by construction — and it is the one failure that stops everything, per
   [`escalate`](../../escalate/SKILL.md).
5. **Raw completions read by a human at the current checkpoint.** Aggregates cannot show
   you what the policy has actually started doing.
6. **The prompt has been searched at least once, untrained.** It is free, it is frequently
   the largest single lever, and its candidates belong in `journal/prompts.md`.
