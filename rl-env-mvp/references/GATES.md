# Gates

The verification ladder in detail, and how to read each measurement. Read before the first
checkpoint.

The ordering matters: each rung assumes the ones below it are green. Reading a probe on a
broken harness produces a confident, precise, wrong answer.

**L0 and L1 are ordinary unit and integration tests** and are not detailed here — they work
the same way in RL code as anywhere else, and [`mvp`](../../mvp/SKILL.md) already covers
them. Two things to carry over from it: split them by what makes them fail (a unit test
goes red when one component changes, an integration test when an interface between two
moves), and never weaken an assertion to reach green.

Both must be passing before L2, and one RL-specific note applies to them: **keep the
verifier and reward as pure functions** so L0 and L1 run in seconds on a laptop with no
accelerator and no model download. If the fast suite needs a GPU, it will stop being run,
and the gates below are the ones that then get skipped too.

This file starts at L2 because that is where the ladder stops being generic — everything
from here is specific to the failure modes of an RL environment.

---

## L2 — Known-good answers score maximum

**The load-bearing gate.** Feed every reference solution through the *whole* scoring path —
prompt formatting, extraction, verifier, reward — and assert it scores maximum.

```python
def test_reference_solutions_score_full_reward(examples):
    """Below 100% is a broken harness, not a weak model."""
    for example in examples[:200]:
        completion = format_as_the_model_would_answer(example.reference_solution)
        assert compute_reward(completion, example, shape).value == shape.correct
```

Run it through the **reward**, not just the verifier. Most breakage lives in the layer
between them — extraction, formatting, type coercion — and a verifier-only test walks
straight past it.

**Why this is first.** A harness that scores correct answers as wrong is indistinguishable
from a hard task in every aggregate you will ever look at. It produces a plausible mean
reward, a plausible learning curve, and a completely wasted run.

If there is no reference solution, say so explicitly in `PLAN.md` and name what replaces
it — a hand-written set of a dozen known-correct answers is enough, and is far better than
nothing.

## L3 — Raw completions read by a human

Print **at least 10 unparsed, unscored completions in full.** Not a sample of the parsed
ones. Not the ones that scored well.

This exists because two separate bugs on the reference project were invisible to every
aggregate and obvious on sight:

```
`(19-12)*7/17+12`        model used single backticks; parser wanted triple
<(22-16)*11/18+18>       model copied the <placeholder> from the prompt verbatim
```

Sound work, wrapped wrong — 54% of rollouts scored zero on **format** while doing correct
arithmetic. Mean reward could not distinguish "task too hard" from "harness wrong". Only
reading the text could.

**What to look for:**

| Symptom | Means |
|---|---|
| Right answer, wrong wrapper | Parser too strict, or the prompt taught the wrong format |
| Cut off mid-thought | Cap too low — check the truncation rate, not the reward |
| Refuses, or answers a different question | Prompt is ambiguous |
| Correct but trivially so | Difficulty dial too low; no headroom to train into |
| Doesn't attempt the behaviour the task needs | **The prompt forbids it.** See below |

**The prompt is a difficulty dial.** On the reference project the prompt said *"Think
briefly"* for a task that is fundamentally a search. Replacing that one string — training
nothing, changing no other setting — took the untrained model from 4.1% to 12.5%.

Before concluding a model is too weak, check that the prompt permits the behaviour the
task requires. A capability the prompt forbids is indistinguishable from a capability the
model lacks, and only one of them is fixable by training.

## L4 — The probe

Sample k rollouts on N examples with the **untrained** model and report the distribution.
No training. This is the go/no-go before spending real GPU time.

Report all of these together — each one alone is misleading:

| Measure | Read it as |
|---|---|
| **task metric rate** | Want roughly 20-80%. Near 0 means nothing to reinforce; near 100 means no headroom |
| **examples solved ≥once** | For group algorithms this matters more than the flat rate — it is the fraction of groups containing something to reinforce |
| **zero-variance groups** | Contribute **exactly zero gradient**. Rising toward 1.0 means the run is doing nothing |
| **reward histogram** | Bimodal at 0 and max means no partial credit is landing. One spike means an attractor |
| **token length + truncation** | A truncated completion scores 0 on *format*. Confusing it with a wrong answer inverts your conclusions |
| **ms per rollout** | Feeds the budget arithmetic. Measure at the cap you will actually train with |

### Reading it

**Task rate near zero.** Training cannot work; no learning rate fixes an empty group. Turn
the difficulty dial, fix the prompt, or use a stronger model. Do not train.

**Zero-variance groups high.** Either the task rate is near 0 or 100, or the reward has too
few tiers to separate rollouts that genuinely differ. This is the metric that most often
goes unlogged and most often explains a dead run.

**A single spike in the histogram.** A tier that every rollout reaches is a flat attractor:
once the policy converges on it, groups go uniform and the gradient vanishes. Grade
*within* that tier so "nearly right" outranks "wildly wrong".

**Solve rate and mean reward disagreeing.** Believe solve rate. The reference project
measured `terse` at mean reward **0.365** / solve rate **4.1%** against `search` at
**0.255** / **12.5%** — selecting on reward would have discarded a 3x improvement in the
thing that matters. The cause was truncation inflating the proxy.

Then check the converse before acting: removing truncation entirely at a 2048 cap left
solve rate **unchanged**, so truncation had been corrupting the *reward* and not hiding
real solves. **Measure the fix, do not assume it.**

## L5 — The smoke run

10-30 real training steps. Not to learn anything — to prove the loop is alive.

| Check | Failure means |
|---|---|
| `grad_norm` finite and non-zero | zero → nothing is training; NaN → numerics broken |
| No OOM at peak, with headroom | the memory ceiling is real, not theoretical |
| Reward metrics appear in the log | the callback is wired; a silently dropped metric is a blind run |
| Loss is finite | numerics |
| **Measured** step time | multiply by the planned step count and compare to the intake budget |

**`grad_norm` at exactly zero is the important one**, and it is quiet. It means every group
had zero reward variance, or an importance ratio underflowed, or the reward returned a
constant. Nothing errors and nothing warns; the run completes and reports a smooth curve.

**Take the measured step time seriously.** If it projects past the intake budget, fix it
now — smaller model, lower cap, fewer steps — and record the choice. A budget discovered
in hour three of a four-hour run is discovered too late.

## L6 — Baseline recorded

Run the untrained policy through `eval.py` and write it into `journal/experiments.md` with its
config snapshot.

Every later claim is a comparison against this number, so it needs the same prompt, the
same cap and the same eval set as the runs it will be compared with. **A baseline measured
under a different prompt is not a baseline.**

State the **noise floor** alongside it. On 200 examples, ±2 is roughly a percentage point,
so a move from 2.0% to 2.5% is not a result — and writing the floor down now prevents it
being read as one later, when the pressure to see movement is higher.

---

## After the ladder

Report in this shape, leading with whatever disproved an assumption:

```
## Environment ready — <task>

**State:** what runs, in one sentence
**Gates:** L2 green (N/N references) · L3 read · L4 probe: <rate>, <dead groups>, <ms/rollout>
**Budget:** <measured step time> x <steps> = <projected>, against a <budget> target
**Baseline:** <task metric> +/- <noise floor>, config snapshot at <path>
**Surprises:** what contradicted the plan
**First experiment:** the queued run and what would falsify it
```

Then stop. The environment is ready to tune, and tuning is a different session.
