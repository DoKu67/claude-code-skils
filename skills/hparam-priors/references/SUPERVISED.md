# Supervised learning

Ordinary supervised training — classification, regression, sequence labelling, encoders —
whether from scratch or fine-tuned from a pretrained backbone.

The regime's defining property: **the objective is the metric's proxy and the gap between
them is the whole risk.** Val loss falling while the task metric stalls is the normal
failure here, not an exotic one.

## Priority order

| Knob | Why here | Start | Search | Coupled with | Failure tell |
|---|---|---|---|---|---|
| **Learning rate** | Dominates everything; wrong by 10× and nothing else is measurable | 1e-3 from scratch (Adam); 1e-5–5e-5 fine-tuning a pretrained backbone | Half-decades, 3 values, then bisect | effective batch | Too high: `grad_norm` spikes, loss `NaN`. Too low: loss falls smoothly and stops far above where it should |
| **Effective batch size** | Sets gradient noise, which sets the usable lr and the wall clock | Largest that fits at green preflight | ×2 / ÷2 | lr — scale together, roughly √ or linear | Too small: noisy val curve, unstable ranking between runs. Too large: smooth curve that generalises worse |
| **Epochs / early stopping** | On small data this is the single largest generalisation lever | Early stop on the held-out metric, patience 2–3 evals | Not a grid — a stopping rule | dataset size, lr | Val loss turning up while train falls |
| **LR schedule + warmup** | Mostly matters at the edges of stability; cosine-to-zero is a safe default | Cosine, warmup 3–5% of steps | linear vs cosine; warmup 0–10% | lr, total steps | Loss spike in the first 100 steps → warmup too short |
| **Weight decay** | Real but second-order next to the above | 0.01–0.1 (decoupled) | 0, 0.01, 0.1 | lr | Train–val gap wide with everything else tuned |
| **Augmentation / regularisation strength** | Where it applies, it beats weight decay for the same purpose | Domain-standard | one dimension at a time | epochs — more augmentation wants more epochs | Underfit at high strength, overfit at zero |
| **Dropout** | Often redundant with the above in modern setups | Architecture default | 0, 0.1 | augmentation | Rarely the binding constraint; if it is, the model is too large for the data |
| **Optimizer choice** | Ranks last because the answer is almost always AdamW | AdamW | Only after the above are peaked | lr — a new optimizer needs its own lr search | — |

`β₁`/`β₂`/`ε` are not axes until everything above is peaked, and a change to them requires
re-searching the learning rate.

## Do not tune

- **Architecture, tokenizer, dataset composition, eval protocol, precision** — frozen
  controls. Moving one starts a new block.
- **Seed** — not an axis. It measures the noise floor; it does not improve anything, and a
  seed selected for a good result is a result that will not reproduce.

## Check before tuning

Each of these has beaten a full hyperparameter search on real projects, and each is free
or nearly so:

1. **Label correctness on a sample of 50, read by hand.** Label noise sets a ceiling no
   learning rate reaches.
2. **Train/val contamination**, by a structural split — hashed key or a time cut, never
   shuffle-and-slice.
3. **Class balance and the metric's sensitivity to it.** Accuracy on a 95/5 split is a
   constant function wearing a metric's clothes.
4. **Normalisation and preprocessing identical between train and eval.** The most common
   cause of a train-falls-eval-flat curve.
5. **Whether the metric is the thing you care about.** Optimising a proxy is fine only
   when the gap has been looked at.
