---
name: experiment
description: "Answer empirical questions by running them — can we do X at all, does X work, does changing X change Y, what does this setting give us — as hypothesis cards run one at a time against a harness the user names, each with a typed answer, a prediction written before the run, and a verdict tied to the run it came from. Use when the user runs /experiment, asks \"can we\", \"does this work\", \"is X faster than Y\", \"what happens if I change X\", \"try this and see\", or when a requirement turned out to be a question nobody knows the answer to. Ends at a verdict table. Not for writing software whose requirements are known, and not for a hyperparameter search over a fine-tune."
---

# experiment

A build claim says "the system SHALL do X"; a failing check means the code is wrong. An
experiment asks "does X hold?", and **Refuted or Inconclusive is a valid answer, not a
defect.** This skill runs a few such questions against something that already exists and
reports what each one returned.

It does three things only: agree the questions, agree the harness, run the questions. It
never writes code (the harness is the current codebase, a directory, or built by
[`build`](../build/SKILL.md)), never edits `SPEC.md`, docs or plans, and never turns a
verdict into a requirement. What to do with the verdicts is the user's call; to build on
one, the user starts `build`.

The rules below are generalized from the fine-tuning skills —
[`tune-loop`](../tune-loop/SKILL.md), [`run-triage`](../run-triage/SKILL.md),
[`tune-report`](../tune-report/SKILL.md), [`tune-preflight`](../tune-preflight/SKILL.md),
[`notes`](../notes/SKILL.md), [`ml_logging`](../ml_logging/SKILL.md) and
[`escalate`](../escalate/SKILL.md). This skill does not call them. For a hyperparameter
search over an SFT or RL run, use `tune-loop` instead; it owns that domain.

---

## Triggers

- **Manual:** `/experiment`, optionally followed by the questions.
- **Automatic:** "can we do X", "does X work", "does X change Y", "what does changing X give
  us", "is A faster than B".

If every possible answer to a question leads to the same next action, it is not an
experiment: say so, and suggest `build`.

---

## 1. Write the hypothesis cards

One card per question, numbered `H-1 … H-n`:

```markdown
### H-2 — vLLM serves Kev-27B
- Statement: vLLM can serve Kev-27B with outputs matching Kev.
- Answer type: true/false            # or integer, float, one of {a, b, c}, or stated
- Answers → decision:
    true  → keep vLLM as a serving candidate
    false → drop vLLM; Kev stays the only engine
    Inconclusive → always allowed; decision deferred
- Precondition: model loads under vLLM without code changes (else Cannot test)
- What is run: engine=vllm on the fixed prompt set
- Measurement: outputs match Kev (true/false), by exact token comparison
- Budget: 30 min wall clock, $15
```

- **Answer type** is whatever the question needs: true/false, an integer, a float, one of a
  set of categories, or another type stated on the card. **Inconclusive is always a legal
  answer.**
- **Answers → decision.** A card where every answer leads to the same decision is not run.
- **Precondition.** What makes the card untestable. If it holds, the verdict is *Cannot
  test* with the reason, and the loop moves on.
- **What is run.** The config or change being tried. Some cards compare against a baseline
  ("does 8,192 use fewer GPU-seconds than 4,096"); many just ask whether something works at
  all. Do not invent a baseline for a card that does not need one.
- **Measurement.** The quantity and its unit, or, for a "does it work" card, the check that
  decides true or false.
- **Budget.** Both wall-clock time and cost, every card.
- **No tolerance picked by judgment.** A bar comes from a measured noise floor, or from a
  real limit the user confirms (the GPU has 80 GB). With neither, the card reports the
  number and the user decides.

## 2. Minimize, then approve

Run [`minimal-cover`](../minimal-cover/SKILL.md) on the cards. Goals are the decisions the
user needs to make; a card survives only if its answer changes one of them. It flags
over-specific goals, tolerances and hard constraints with a recommendation each. The user
approves or edits the cards.

## 3. Propose an order; the user decides

Propose an order with one line of reason per card. Default: **cheapest decisive card
first**, and cheap cards that can close off an option early go before expensive ones that
assume it is open. Then ask. The user may rank something higher for reasons the cards do not
show; their order wins.

## 4. Agree the harness, explicitly

A **harness** is whatever the experiment runs: given one config, it runs the system under
test on fixed inputs and writes one record of measurements. **Always ask which it is; never
guess:**

- **The current codebase, or a directory the user names.** Read it, then show the user the
  exact command, which setting each card changes and how, the fixed inputs, and where each
  measurement is read from. Wait for confirmation. If a card needs a setting or measurement
  the code does not expose, that is a harness gap: offer a harness request to `build`
  rather than patching the code here.
- **A new harness.** Derive a harness request from the approved cards and send it to
  `build`:

| Field | Filled from |
|---|---|
| Settings, with allowed values | every setting any approved card changes |
| Fixed inputs | the workload the cards are about, identical on every run |
| Measurements, with units | every quantity or check any card reads |
| Record format | run ID, git SHA, harness version, config, raw outputs, measurements |
| Validity checks | a known input gives the known answer; the same config twice gives the spread |
| Out of scope | anything no card changes or measures |

`build` replies with a harness version, its one command, and passing validity checks.

## 5. Validity checks, then a baseline if one is needed

**Before any card:** run a known input and confirm the known answer. If that fails, or the
raw outputs are nonsense, it is a **harness bug, not a result**. Send `build` a bug report
(the failed check, the exact input and config, expected versus got, the harness version and
run ID) and record no verdict until a fixed version passes.

**Only if some card compares against a baseline:** run the baseline config at least twice.
The spread between those runs is the **noise floor**. Record it with the harness version.
"Does it work" cards skip this step.

## 6. Run the cards, in the approved order

For each card:

1. **Precondition.** If it blocks the card, record *Cannot test* and the reason; next card.
2. **Prediction first.** Write the predicted answer to the record before launching. A
   prediction written after the run is a rationalization.
3. **Estimate time and cost.** If either exceeds the card's budget, stop and ask.
4. **Run** the card's config through the harness command, with a tqdm progress bar
   (step rate and ETA). A comparing card runs the baseline and its one change the same
   number of times. **One change per card**; two changes at once answer neither.
5. **Record** one append-only entry per run: run ID, timestamp, git SHA, harness version,
   config, raw outputs, measurements.
6. **Read the raw outputs before the number.** Invalid outputs are a harness bug (step 5),
   never a *Refuted*.
7. **Verdict.**

| Answer type | Supported | Refuted | Inconclusive |
|---|---|---|---|
| true/false, category | answer equals the prediction | answer differs | the run could not decide it |
| number, against a baseline | difference beyond the noise floor, in the predicted direction | beyond the floor, the other way | within the noise floor |
| number, no baseline or bar | report the value; the user judges it | | |

Record the answer, the verdict and the run IDs together, immediately.

## 7. Stop and ask only when it matters

Stop mid-loop only when the answer changes what happens next **and** no affordable run can
settle it: a budget exceeded, the same failure twice, a harness bug that blocks every card,
or a card whose precondition the user must decide. Ask with the facts measured, two or three
priced options and a recommendation, and say what happens if there is no answer.

## 8. Report the verdict table, then stop

```markdown
| Card | Prediction | Answer | Noise floor | Verdict | Runs |
|---|---|---|---|---|---|
| H-2 vLLM serves Kev-27B | true | false (parity 0/500) | n/a | Refuted | r-0412 |
| H-1 8,192 vs 4,096 GPU-s/1k | −10% | −3.1% | ±4.0% | Inconclusive | r-0409, r-0410, r-0411 |
| H-3 SGLang loads model | true | n/a | n/a | Cannot test: needs custom kernel | — |
```

Under it, list what was not run and why (dropped by minimal-cover, over budget, blocked).
Refuted and Cannot test count as much as Supported. Then stop.

---

## Out of scope

Writing or fixing code, including the harness. Editing `SPEC.md`, plans or docs, or
sweeping them for stale claims. Turning verdicts into requirements. Starting a build. A
hyperparameter search over a training run.

## Done when

Every approved card has a verdict (Supported, Refuted, Inconclusive or Cannot test) with the
run IDs it came from, every prediction was recorded before its run, no verdict came from a
harness that failed a validity check, and the user has the verdict table.
