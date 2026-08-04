# Preference methods and reward models

DPO, KTO, ORPO, IPO and their relatives, plus the reward-model training that RLHF's policy
stage depends on.

The regime's defining property: **the objective can be satisfied without the behaviour
improving.** A preference loss rewards separating chosen from rejected, and separating them
by degrading the rejected side counts. This is why the held-out task metric and the raw
outputs matter more here than the loss curve does.

## Priority order — DPO and relatives

| Knob | Why here | Start | Search | Coupled with | Failure tell |
|---|---|---|---|---|---|
| **β (KL / deviation strength)** | The defining knob of the method; the single largest lever | 0.1 | 0.01, 0.05, 0.1, 0.5 — half-decades | lr; pair quality | Too low: both chosen and rejected logprobs collapse together while margin grows — the policy is fleeing the reference. Too high: nothing moves |
| **Learning rate** | Preference training wants roughly an order of magnitude less than SFT | 5e-7–5e-6 full FT; 1e-5–5e-5 LoRA | Half-decades | β | Too high: degenerate outputs within a few hundred steps |
| **Epochs** | Overfits even faster than SFT; margin keeps growing after the behaviour has stopped improving | 1 | 1, 2 | dataset size | Held-out preference accuracy peaks and falls while train margin climbs |
| **Reference model choice** | Which model the KL is measured against changes what β means | The SFT checkpoint being tuned | SFT checkpoint vs base | β | A reference far from the policy makes β behave unpredictably |
| **Effective batch size** | Preference gradients are noisy; small batches are unstable | 32–64 pairs | ×2 / ÷2 | lr | Jagged margin curve, unstable run-to-run ranking |
| **Loss variant** | ORPO drops the reference model; KTO takes unpaired signal; IPO changes the objective's shape | DPO | Only after β is peaked | everything — a variant change is a **new block** | — |
| **Label smoothing / cDPO** | Buys robustness to annotation noise | 0 | 0, 0.1 | pair quality | Helps only when the labels are known to be noisy |
| **SFT-loss mixing weight** *(where supported)* | Keeps the policy anchored to the response format | 0 | 0, 0.1 | β | Format degradation is the symptom it treats |

## Priority order — reward models

| Knob | Why here | Start | Search | Failure tell |
|---|---|---|---|---|
| **Learning rate** | As with any classifier head on a pretrained trunk | 1e-5–5e-6 | Half-decades | Held-out pair accuracy stuck near 50% |
| **Epochs** | One pass is usually enough; more memorises annotator artefacts | 1 | 1, 2 | Train accuracy near 100%, held-out far below |
| **Head init and pooling position** | Silent correctness issue more than a search axis | Last non-padding token | Verify, do not sweep | Accuracy at chance with a healthy-looking loss |
| **Length normalisation / debiasing** | Length is the shortcut every preference dataset contains | On, if the data is length-biased | on / off | Reward correlates with response length on held-out |

## Do not tune

- **Base model, reference model, pair dataset, chat template, precision, eval protocol** —
  frozen controls.
- **The loss variant** as an axis inside a block. DPO → KTO is a different method, not a
  different value.

## Check before tuning

1. **Chosen and rejected are not swapped.** Sample 20 pairs and read them. A swapped
   dataset trains perfectly well and produces a confidently worse model.
2. **The pairs are actually distinguishable by a human** on the dimension you intend. If
   they are not, the margin will still grow — on whatever else differs.
3. **Length bias, measured.** Mean token count of chosen vs rejected. If chosen is
   consistently longer, length is what will be learned, and every downstream number will
   reflect that rather than quality.
4. **The policy started from the SFT checkpoint**, not the base model, unless a reason says
   otherwise.
5. **A held-out task metric exists that is not the preference loss.** Without one, the
   regime's defining failure is invisible: you cannot tell improvement from
   reward-satisfying degradation.
6. **Raw generations read at each checkpoint.** The fastest detector of the collapse
   failure, and it is not visible in the margin.
