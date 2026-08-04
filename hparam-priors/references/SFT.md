# SFT — instruction and chat fine-tuning

Supervised fine-tuning on prompt/response pairs, full-parameter or adapter.

The regime's defining property: **it overfits far faster than people expect.** One to three
epochs is the usual range, the model has already seen most of the underlying capability
during pretraining, and the risk is not underfitting but burning the model's generality
into one narrow response style.

## Priority order

| Knob | Why here | Start | Search | Coupled with | Failure tell |
|---|---|---|---|---|---|
| **Learning rate** | The dominant knob, and the range is narrow | 1e-5–2e-5 full FT; 1e-4–2e-4 LoRA | Half-decades, 3 values | LoRA rank/alpha; batch | Too high: outputs degrade into repetition or the model loses instruction-following. Too low: style barely shifts |
| **Epochs** | The generalisation lever; the difference between 1 and 3 is usually larger than a decade of lr | 1–2 | 1, 2, 3, with held-out eval per epoch | dataset size | Val loss turns up inside the first epoch on small data |
| **LoRA rank + alpha** *(adapter runs)* | Sets capacity; rank alone is meaningless without alpha | r=16, α=32 (α ≈ 2r) | r ∈ 8, 16, 32, 64, holding α = 2r | lr — higher rank wants lower lr | Rank too low: the target style never lands. Too high: full-FT-like overfitting with none of the savings |
| **LoRA target modules** | Bigger effect than rank on many tasks, and routinely left at a default | All attention + MLP projections | attention-only vs all-linear | rank | Attention-only underfits tasks needing new knowledge |
| **Effective batch size** | Small batches make SFT unstable in a way that looks like a bad lr | 64–128 sequences | ×2 / ÷2 | lr | Loss curve jagged, run-to-run ranking unstable |
| **Max sequence length** | A cost knob and a correctness knob at once | The 95th percentile of the data, rounded up | Set from the length distribution, not searched | packing, memory | Truncation cutting answers mid-response — check the truncation rate, not the mean length |
| **Packing on/off** | Throughput, and a correctness risk if attention is not isolated per example | On, with cross-contamination masking verified | on / off | seq len | Packing without per-example attention masking silently trains on cross-example attention |
| **Warmup + schedule** | Matters most in the first epoch, which on SFT is most of the run | Cosine, warmup 3–10% | 0.03, 0.1 | lr | Early loss spike |
| **NEFTune / noise, label smoothing** | Real but small, and only after the above | Off | Off, then one value | — | — |

## Do not tune

- **Base model, chat template, tokenizer, precision, dataset mix, eval protocol** — frozen
  controls. Each starts a new block.
- **Loss masking policy** — not an axis, a correctness decision. Loss on completion tokens
  only is the default; training on prompt tokens too is a deliberate choice with a reason,
  not a knob to sweep.

## Check before tuning

These cause more failed SFT runs than every hyperparameter combined:

1. **The chat template used in training is byte-identical to the one used at eval and at
   inference.** Print both and diff them. A mismatch produces a model that trained fine and
   behaves as if it did not.
2. **Loss is masked over prompt tokens.** A loss that starts suspiciously low is the tell.
3. **Special and EOS tokens are where you think.** A model that never learns to stop was
   trained without an EOS it could see.
4. **Read 10 fully rendered training examples**, template applied, tokenized and decoded
   back. Not the raw records — what the model actually receives.
5. **Data quality over data quantity.** A thousand curated examples routinely beat fifty
   thousand scraped ones, and no learning rate closes that gap.
6. **Contamination against the eval set**, by hash or near-duplicate match.

Only when all six are green does the priority table above start to matter.
