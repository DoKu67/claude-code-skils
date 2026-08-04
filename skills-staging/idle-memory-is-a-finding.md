---
id: idle-memory-is-a-finding
target: tune-preflight
kind: rule
signal: correction
status: staged
occurrences: 2
threshold: 3
---

**Rule:** A peak far *below* the ceiling is a finding, not a pass. When the estimate or the
measured peak lands under ~50% of the device, report it as **undersized** and say what the
spare memory could buy — a larger batch, more prompts per step, a longer sequence — before
launching. The verdict table's Green band currently spans everything under 70%, which
silently blesses a run using a third of the card.

Two arithmetic checks that turn the "why" into a number:

- **KV cache is often not the driver.** Under grouped-query attention it can be an order of
  magnitude below intuition — a 3B model with 2 KV heads costs ~0.04 MB/token, so a
  64-sequence generation batch is ~1.2 GB. The real driver is usually the logits tensor,
  `micro_batch x seq x vocab`, which at a 152k vocab is ~1.2 GB for a micro-batch of 8.
- **`utilization.gpu` near 100% is not evidence of efficiency.** It measures the fraction of
  time a kernel is resident, not throughput. Autoregressive decode pins it at ~99% while
  doing a matrix-*vector* product per step — bandwidth-bound and arithmetically idle. High
  util with half the memory free is a diagnosis, not a clean bill of health.

**Prediction:** If this fires, an undersized batch is caught at the first preflight rather
than after a noise floor makes a block of results unusable.
**Falsified if:** the flag fires on runs that are small for a good reason — a deliberate
memory-constrained baseline, a debug run, a model that cannot use more batch — often enough
to become noise. Then it belongs only in the first preflight of a project, not every one.

**Occurrences**
- 2026-08-04 · session 1baba5b8 · correction · *"are we being efficient with the gpu? I see
  that we're only using about 1/2 the total memory, but the GPU-util is ~99%"* — the assistant
  answered the util question correctly, diagnosed a bandwidth-bound decode, and then proposed
  a **vLLM swap** rather than the batch increase sitting in front of it. The user rejected
  that and had to raise the same issue again.
- 2026-08-04 · session 1baba5b8 · correction · *"Why so few questions? Don't we have GPU
  memory? Can't we have larger batches?"* — needed because the first correction did not land.
  `per_device_train_batch_size: 8 x accumulation 8 / 8 rollouts = 8 distinct problems per
  gradient step`, written at intake as a placeholder, survived the whole `rl-env-mvp` build,
  the L4 probe, five runs and a seven-gate ladder without ever being justified. Measured
  peak was **13.6 GB of 32** — Green by the current table. Doubling the batch measured
  21.2 GB and **13% cheaper per problem** (2.26 → 1.96 s), and the undersized batch was the
  root cause of a ±9.9pp noise floor that made a whole block of results unreadable.
