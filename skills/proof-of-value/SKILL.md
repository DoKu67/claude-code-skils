---
name: proof-of-value
description: Prove, or fail to prove, that a task's acceptance criteria actually discharge the specific plan element (an objective's bar, a constraint, a decision) it claims to serve — numbered premises each tagged with a source, an explicit attempt to construct a counterexample, and a verdict of Proved / Conditional / Open. Use when the user says "prove this task is worth doing", "justify this ticket", asks for a proof of value per component, or when `sprint-tasks` is producing a task's Proof of value section. Never used to argue that a plan's objective itself is the right objective — that is `plan-doc`'s and the user's call, not provable here.
---

# proof-of-value

A justification paragraph can say anything. A proof has to survive an attempt to break it.
This skill exists because "this task matters because it improves reliability" is not a
claim anyone can check — it isn't even false, because it isn't precise enough to fail. The
discipline here is narrow and mechanical: state exactly what the task's acceptance criteria
are supposed to discharge, list every fact the argument leans on with where it came from,
try to construct a case where the criteria hold and the target still fails, and report what
happened.

**This proves sufficiency, not worth.** It answers "if this task's acceptance criteria all
hold, is the specific plan element it targets actually satisfied?" — not "is this the right
thing to be building." The second question is the plan's, settled under `plan-doc`'s
*Objective* and *Decided* sections, and is out of reach of this skill; see
[Out of scope](#out-of-scope).

---

## The format

```markdown
## Proof of value: [Task title]

**Discharges:** Plan → [Next step N | Constraint C | Decided D] — [the specific falsifiable
bar or requirement being targeted, quoted or closely paraphrased]

**Claim:** If every acceptance criterion of this task holds, then [the bar above] is
satisfied.

**Premises:**
1. [...] — source: this task's Acceptance criteria
2. [...] — source: this task's Acceptance criteria
3. [...] — source: Plan → Constraint / Decided
4. [...] — source: Assumption (unverified)

**Argument:**
1. [step connecting premises toward the claim]
2. [...]
n. Therefore, [claim] — the target is satisfied.

**Attempted counterexample:** [a concrete case where every premise holds but the target
still fails — or a stated reason none could be constructed]

**Falsifier:** [what future observation would invalidate this proof]

**Verdict:** Proved | Conditional on [assumption] | Open — [counterexample found; the
missing acceptance criterion is: ...]
```

Every field appears every time, in this order. A proof missing *Attempted counterexample*
is not a proof — it is the argument's author grading their own homework.

---

## What each field must actually do

| Field | Requirement | Common failure it exists to catch |
|---|---|---|
| **Discharges** | Names one specific, already-falsifiable element of the plan — a next step's stated falsifier, a constraint, a decision. Never "the plan's overall goals." | Proving against a vague target proves nothing, because nothing could fail it |
| **Claim** | The sufficiency statement, always in the same "if AC then target" shape | A claim like "this task is valuable" isn't a claim, it's a mood |
| **Premises** | Each one tagged with its source — this task's own AC, the plan's Constraints/Decided, or an explicit unverified Assumption | An untagged premise hides whether the proof rests on a fact or a guess |
| **Argument** | Numbered steps, each a valid inference from the numbered premises to the claim | A prose paragraph that "explains" the connection without showing the steps is not checkable |
| **Attempted counterexample** | A real, specific scenario tried in earnest — not "none apply" without having looked | Skipping this is where hand-waving hides |
| **Falsifier** | What would prove this proof wrong later, even after a Proved verdict | Without it, "Proved" becomes permanent and unrevisitable |
| **Verdict** | One of exactly three states, each with a required consequence — see below | A verdict that doesn't change what happens next isn't a verdict |

**A premise that is itself an algorithmic-correctness claim** ("the dedup logic actually
removes all duplicates", "this migration is idempotent") is not proved here — that is
[`code-proof`](../code-proof/SKILL.md)'s job. Run it on that specific claim and cite its
Verdict as a Premise here, tagged `source: code-proof`. This skill proves that acceptance
criteria discharge a plan's bar; it does not itself verify that an algorithm is correct.

---

## The three verdicts, and what each one obligates

- **Proved.** Every premise traces to the task's AC or the plan's settled sections — zero
  assumptions — and no counterexample was found despite a real attempt. The task proceeds
  as written.
- **Conditional on [assumption].** The argument is valid, but at least one premise is an
  unverified assumption. **That assumption must also appear in the task's own Dependencies
  and constraints section** — a proof's assumption that isn't echoed back into the ticket is
  a fact nobody downstream will see. Conditional is not a lesser pass; it is an honest one,
  and it names exactly what would upgrade it to Proved.
- **Open.** A counterexample was found: the acceptance criteria, even fully met, do not
  entail the target. This is the valuable failure mode, not an embarrassment — it means the
  ticket has a real gap. The fix is to add the missing acceptance criterion in
  [`sprint-tasks`](../sprint-tasks/SKILL.md) and re-run the proof, not to soften the target
  or narrate around the gap. If the gap is in the plan rather than the ticket — the plan's
  stated bar can't be discharged by any acceptance criterion because the plan itself is
  underspecified — that is a finding for [`plan-doc`](../plan-doc/SKILL.md), and belongs
  there, not smoothed over here.

---

## Rules

- **No invented numbers.** If the plan's target is numeric (a latency bound, an error-rate
  ceiling) and the task's acceptance criteria don't yet carry a matching number, that is an
  Open verdict with the missing bound named — never a plausible-sounding figure invented to
  complete an inequality. Where both the target and the criteria are numeric, use the actual
  arithmetic; that is the case where this proof is most literally mathematical.
- **A premise cannot restate the claim.** "This task is valuable because it delivers value"
  is circular; every premise must be a fact independent of the conclusion.
- **Composed proofs inherit their weakest link.** If this task's proof depends on a sibling
  task's claim (its premise is "Depends on: Proof of [Task B]"), this proof's verdict can be
  no stronger than Task B's. A Proved proof built on a Conditional or Open dependency is
  itself at best Conditional — say so, and say which dependency caps it.
- **The counterexample attempt is genuine or it says why it's short.** If time didn't allow
  a deep search, say "not exhaustively searched" rather than implying a confident search that
  didn't happen — an unsearched "none found" is worse than an honest gap.
- **A proof is re-run whenever the acceptance criteria it covers change.** A stale Proved
  verdict attached to criteria that have since been edited is a false signal, not a saved
  step.

---

## Worked example

Task's acceptance criteria (from [`sprint-tasks`](../sprint-tasks/SKILL.md)'s own worked
example, before correction):

```markdown
- Given a key under its quota, when it makes a request, then the request succeeds with no
  added latency beyond counting overhead.
- Given a key over its quota, when it makes a request, then it receives 429 with a
  Retry-After header.
- Errors and edge cases: a key with no requests in the last 60s resets to full quota; the
  counting store being unavailable fails open.
```

Target, from the plan: *"Falsifier: p99 latency for compliant callers regresses more than
5ms."*

```markdown
## Proof of value: Public API requests are rate-limited per API key

**Discharges:** Plan → Next step 1 — "p99 latency for compliant callers must not regress
more than 5ms"

**Claim:** If every acceptance criterion of this task holds, then p99 latency for compliant
callers regresses by at most 5ms.

**Premises:**
1. AC1: a compliant caller's request succeeds with no added latency beyond counting
   overhead — source: this task's Acceptance criteria.
2. Counting overhead is not bounded by any acceptance criterion — source: this task's
   Acceptance criteria (an absence, not a stated fact).

**Argument:**
1. From AC1, the added latency for a compliant caller equals the counting overhead, whatever
   that overhead turns out to be.
2. Premise 2 places no upper bound on that overhead.
3. Therefore the claim does not follow: AC1 is consistent with a counting overhead of, say,
   8ms, which would satisfy AC1 while breaching the plan's 5ms bar.

**Attempted counterexample:** A counting-store implementation with p99 lookup latency of 8ms
under load. It satisfies AC1 exactly as written (compliant callers see "no added latency
beyond counting overhead" — true by construction) while failing the plan's target. Found on
first attempt; not an edge case.

**Falsifier:** N/A while Open — the proof already failed.

**Verdict:** Open — counterexample found. The missing acceptance criterion is a numeric
bound: "Counting overhead adds no more than 5ms to p99 latency for compliant callers."
```

That gap gets added back into the task via [`sprint-tasks`](../sprint-tasks/SKILL.md); the
corrected acceptance criteria (with the bound in place) yield a Proved verdict, since the
argument now closes: AC1-with-bound plus the counting-overhead premise together entail the
plan's 5ms target directly, and no counterexample was found on a real attempt.

---

## Out of scope

**Whether the plan's objective is the right objective.** This skill never argues that
rate-limiting the API, or any other item in the plan, is a good idea in the first place —
that judgment belongs to the plan's own *Objective* and *Decided* sections, settled by the
user, per [`plan-doc`](../plan-doc/SKILL.md). This skill only checks whether a task's
acceptance criteria actually get you there, once "there" is already decided.

**Empirical verification.** A Proved verdict is a design-time logical check — it says the
acceptance criteria, if true, would satisfy the target. It says nothing about whether the
shipped code actually satisfies its acceptance criteria; that is testing and
[`run-triage`](../run-triage/SKILL.md)'s territory, after the code exists.

**Probability or expected-value arguments with invented inputs.** No made-up confidence
levels, no fabricated priors dressed up as Bayesian rigor. Where the plan and the task
genuinely carry no numbers, the proof is structural — valid inference over stated facts —
not quantitative theater.

---

## Done when

Every proof names one specific plan element under *Discharges*; the *Claim* is the
if-AC-then-target sufficiency statement; every premise is tagged with a source and none
restates the claim; the *Argument* is numbered steps, not prose; a real *Attempted
counterexample* is documented, including a found one; *Falsifier* is stated for any Proved
or Conditional verdict; the verdict is exactly one of Proved / Conditional / Open with its
required consequence carried out — a Conditional's assumption echoed into the task's
Dependencies and constraints, an Open's missing criterion named and routed back to
`sprint-tasks` or `plan-doc`; and no premise, argument step, or number in the proof is
invented.
