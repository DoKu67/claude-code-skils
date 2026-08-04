---
name: escalate
description: Stop and ask the user, in the shape that makes answering cheap — when a tuning loop is stuck, a budget is running out, a run is about to OOM, a reward looks hacked, or the next useful change is one only they can authorise. Use when a long-running or autonomous loop hits a decision it should not make alone, when the same failure repeats, when a mitigation would invalidate earlier results, and whenever something irreversible or expensive is about to happen. Also use to decide whether a question is worth asking at all.
---

# escalate

An autonomous loop that never stops to ask is not more useful than one that does — it is
just harder to trust. **Stopping to ask is a result**, and it belongs in the record like
any other.

The design goal is that the human moves up the stack, not out of the loop: they should be
answering questions about direction, cost and risk, not reconstructing a debugging session
from a wall of logs. That is what the message shape below is for.

Used by [`tune-loop`](../tune-loop/SKILL.md), [`tune-preflight`](../tune-preflight/SKILL.md)
and [`run-triage`](../run-triage/SKILL.md), and available to any long-running work.

---

## The test

**Escalate when the answer changes what happens next *and* you cannot get it from a
measurement you could afford to run.**

Both halves matter. A question you could answer with a 20-minute probe is a probe, not an
escalation. A measurement whose result would not change the next action is not worth
running either.

Do **not** escalate to: ask permission to continue a plan already agreed; confirm a choice
that has an obvious default; report progress that nothing depends on; or hand over a
decision because it feels consequential. Those train the user to stop reading.

---

## Triggers

Defaults. A project may override any of them — record the overrides in `PLAN.md` so the
threshold is visible rather than remembered.

### Stop immediately, before doing anything else

| Trigger | Why it cannot wait |
|---|---|
| **Preflight red** — projected peak > 90% of device | Launching corrupts the block and wastes the slot. Nothing launches until answered |
| **Suspected reward hacking** — reward ↑ while held-out metric flat or ↓ | Every further run climbs the wrong hill; the longer it runs the more convincing the wrong result looks |
| **Second OOM in a block** after a mitigation | The estimate is wrong in a way another guess will not fix |
| **Cost or disk about to overrun** | Both fail in ways that look like training bugs |
| **Anything irreversible** — deleting checkpoints, overwriting a run directory, pushing weights, publishing | Not recoverable by trying again |

### Stop at the end of the current run

| Trigger | Default threshold |
|---|---|
| No improvement | 3 consecutive runs inside the noise floor |
| Budget | 70% of the agreed GPU-hours or wall clock spent |
| Same failure signature twice | after one fix attempt |
| The useful next change is a **frozen control** | always — that decision invalidates the block and is the user's |
| A mitigation would invalidate the block | see the ladder in [`tune-preflight`](../tune-preflight/SKILL.md) |
| The metric is behaving in a way you cannot explain | after one investigation attempt |

---

## The message

Four parts, in this order, and nothing else. The target is that the user can answer in one
line without opening a file.

```markdown
**Stuck: three runs inside the noise floor on block 2.** Not launching anything further.

| run | lr | k | temp | metric | Δ vs best |
|---|---|---|---|---|---|
| `calm-heron` | 1e-4 | 8 | 1.0 | **0.155** | — |
| `swift-lynx` | 2e-4 | 8 | 1.0 | 0.149 | −0.006 (noise) |
| `bold-pika`  | 1e-4 | 16 | 1.0 | 0.158 | +0.003 (noise) |
| `wry-tapir`  | 1e-4 | 8 | 0.7 | 0.151 | −0.004 (noise) |

**What I think:** the axes inside this block are exhausted — noise floor ±0.012 and
nothing has cleared it since `calm-heron`. The remaining levers are frozen controls,
so I can't move them without invalidating the block. 4.7 of 12 GPU-h spent.

**Options**
| # | Change | Hypothesis | Cost | Invalidates block |
|---|---|---|---|---|
| 1 | Reward shape → `graded` | dead-grp 0.03 says spread is thin; partial credit widens it | 1.5 h | yes, new block |
| 2 | Base model 3B → 7B | 0.155 may be a capacity ceiling, not a tuning one | 4 h + preflight | yes, new block |
| 3 | Stop here, write up 0.155 | — | 0 | no |

**Recommendation: 1.** Cheapest, and it tests the ceiling-vs-signal question directly —
if a wider reward moves nothing, that is evidence for option 2 rather than a guess.

**If you don't answer:** nothing launches. The queue is paused, not dropped.
```

Rules that make it work:

- **The grid comes first**, compact — 3–6 rows, only the axes that varied. It is the
  evidence, and it is what lets the user disagree with your read.
- **Separate what you measured from what you believe.** They carry different weight and
  merging them is how a guess gets adopted as a finding.
- **Two or three options, priced**, each saying whether it invalidates the block. An
  escalation with one option is a request for permission; with five it is a request for
  the user to do the thinking.
- **Recommend one**, with the reason. You have the context; withholding a recommendation
  is not neutrality, it is offloading.
- **Say what happens if they do not answer**, always. For a danger-class trigger the
  answer is always "nothing runs".
- **Batch the questions.** Everything you need, once. Three escalations an hour apart is
  the fastest way to have all of them ignored.

---

## Wording

State the situation and the number. No apology, no alarm, no hedging.

**"Projected peak 78 GB against an 80 GB device. Not launching."** — not "I'm a bit worried
this might possibly OOM, sorry to bother you."

An escalation is a status report with a decision attached. Anything that reads as
apologising for the interruption makes the interruption harder to act on.

---

## Record it

The escalation and its answer go in `journal/experiments.md` per
[`notes`](../notes/SKILL.md), with the
date and the runs it came from. It is the moment the project changed direction, and the
reasoning that produced it is exactly what a later session cannot reconstruct from the
grid alone.

If the answer establishes a standing preference — a threshold, a budget rule, a hardware
constraint — it goes in `PLAN.md` too, so the next loop uses it instead of asking again.

---

## Out of scope

Routine progress reporting. Interactive checkpoints during a build — those belong to
[`mvp`](../mvp/SKILL.md) and are a different thing: a checkpoint is scheduled and expected,
an escalation is triggered and unplanned.

---

## Done when

The message leads with the situation in one line; the grid is there and is small; measured
and believed are separated; there are two or three priced options each marked for whether
it invalidates the block; one is recommended with a reason; the no-answer default is
stated and is "nothing runs" for anything in the danger class; and the escalation is
recorded in `journal/experiments.md` — on the entry it arose from, or as its own entry if it
arose between runs — with the runs that produced it.
