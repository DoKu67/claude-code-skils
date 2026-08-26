---
name: code-proof
description: Produce a checkable correctness proof for a piece of code, an algorithm, or a procedure — a formalized claim, independently-discharged lemmas, a composed proof using the technique that fits the claim's shape (induction / contradiction via minimal counterexample / finite case-analysis / reduction to a trusted reference), a genuine attempted refutation, and a verdict of Proved / Disproved / Unresolved. Never returns Proved for a claim quantified over an unbounded parameter unless a valid induction actually closes it. Use when the user asks to prove a function, algorithm, or procedure correct, asks "is this really race-free / idempotent / never-stale", or wants a rigorous correctness argument rather than a claim backed only by tests passing. Distinct from `proof-of-value`, which proves a task's acceptance criteria discharge a plan's bar — not that code is mathematically correct.
---

# code-proof

A proof that only sounds rigorous is worse than an admission of doubt, because it is
believed. This skill exists to keep that from happening: every claim is stated precisely
enough to be wrong, every lemma is discharged on its own before it is used, and every proof
gets a real, documented attempt to break it before a verdict is allowed.

**The single rule that matters most:** most correctness claims about code are universally
quantified — *for all inputs*, *for all interleavings*, *for all N*. A claim shaped like that
cannot be checked by looking at cases; it can only be closed by an argument that holds for an
arbitrary instance without enumerating them. If no such argument is found, the honest verdict
is *Unresolved*, not *Proved*. Nearly every failure mode below is a version of this rule
being skipped.

---

## The format

```markdown
# Correctness proof: [the claim, one sentence, sharply bounded]

## Formalization

- Objects and state: [precise definitions of the inputs, data structures, and invariants in
  play — not a restatement of the code, a specification of what it means]
- Claim: [the property as a precise predicate, relation, or inequality — not prose]
- Unbounded?: Yes — quantified over an unbounded parameter (input size, thread/process
  count, iteration count, recursion depth) | No — a fixed, finite, checkable instance

## Lemmas

1. [statement] — proved by [technique] — used in step [n] of the Proof
2. [statement] — proved by [technique] — used in step [n] of the Proof

## Proof

1. [step, citing which lemma or prior step it uses]
2. [...]
n. Therefore, [the claim] holds.

## Attempted refutation

[A real, specific attempt to break the claim — targeting the boundary/base case and any step
the Proof treats as obvious. If Unbounded: Yes, explicitly check that the induction actually
closes — that the hypothesis used is strong enough to imply itself one step later — rather
than asserting "by IH" and moving on. State what was tried and what happened.]

## Falsifier

[What would invalidate this proof later — a code change, a removed assumption, a case not
yet considered]

## Verdict

Proved | Disproved — counterexample: [...] | Unresolved — [why: unbounded claim with no
valid induction found; case space not shown finite; the technique used doesn't fit the
claim's shape and no other was tried]
```

Every section appears every time. A proof missing *Attempted refutation* is an assertion
wearing a proof's clothes.

---

## The technique menu — exactly four, picked by the claim's shape

Every technique below is sound in its home domain and silently produces false confidence
outside it. Picking one that doesn't fit the claim's shape is itself the most common way this
skill fails, so name the shape before picking the technique.

| Technique | Fits when | Fails when |
|---|---|---|
| **Induction** (structural or strong, over the input/data type's recursive shape) | The object being reasoned about is genuinely recursive — list length, tree depth, recursion depth | The property being carried through the recursion isn't itself inductive — a height/balance invariant, an accumulator relative to the answer, a memoized DAG rather than a tree. Using it here without stating a strengthened hypothesis as its own lemma is the single most common failure — see below |
| **Contradiction via minimal counterexample** | The domain has a genuine well-founded decreasing measure the algorithm itself produces (array length, recursion depth) | Iterative/stateful code with mutable accumulators, or concurrent interleavings, has no such measure to reduce along — "assume the earliest failing interleaving" has nothing underneath it. Also concentrates all its rigor in the reduction step and waves through the base case, which is exactly where off-by-one and boundary bugs live |
| **Finite case-analysis** | The case space is genuinely, statically enumerable — a fixed set of branches, no loop or recursion inside any case | Any unbounded parameter inside the space (a loop, a recursion, an arbitrary-length collection) forces a catch-all row ("n ≥ k: general case") that is an unstated inductive leap dressed as a table row |
| **Reduction / simulation to a trusted reference** | An already-correct reference (a prior version, a naive implementation, a known-correct algorithm) exists and the target simulates it step for step | The target diverges from the reference in step granularity or order — batching, memoization, reordering, laziness, concurrency — and lockstep simulation no longer holds. Use a stated weaker relation (eventual/observational equivalence) instead of defaulting to lockstep and hoping |

**A claim marked `Unbounded: Yes` can only reach Proved via Induction (with an explicitly
strengthened hypothesis, stated as its own lemma) or Reduction to an already-general result.**
Case-analysis and contradiction-via-minimal-counterexample cap at *Unresolved* — or, if a
stakes-appropriate bounded check passed cleanly, the Verdict says so honestly ("tested against
N ≤ 10,000, not proved for all N"), never silently upgraded to Proved.

---

## Lemmas: independent, and never smuggling

- **A lemma proves one fact, using only prior lemmas and the Formalization's definitions —
  never the Claim itself.** A lemma that restates the claim is circular.
- **If the Proof needs a stronger fact than a lemma currently states, that strengthening
  becomes a new, separate, numbered lemma** — never an unstated leap folded into the Proof's
  narration. This is the concrete fix for induction's most common failure: "by IH the
  subtree is balanced, so after rotation the whole tree is balanced" is false as stated,
  because balance alone doesn't carry through rotation — height does. The strengthened
  hypothesis (height, not just balance) has to be its own lemma, stated and proved, before the
  Proof is allowed to use it.
- **Each lemma names its own technique from the menu above**, independently of what the main
  Proof uses. A lemma about a bounded sub-property may use case-analysis even inside a proof
  whose overall claim is unbounded.

---

## Attempted refutation: not self-grading

The default is a real, separate pass within the same task: set the derivation aside, look
only at the Formalization, and hunt specifically for what proofs conventionally skip — the
empty/base case, the off-by-one boundary, the step everyone would call "obviously fine." State
what was tried, not just that nothing was found.

**For a high-stakes claim** — concurrency, data loss, security, financial correctness — escalate
to a genuinely separate agent call (a fresh `Agent` invocation, not a fork of this context)
given only the Formalization, never the Proof or the Lemmas. A blind re-derivation from the
same context still shares the same blind spots about what counts as "obvious"; a truly
separate agent at least removes the shared derivation, even if it can't remove a shared prior.

An unsearched "none found" is worse than an honest gap — if the search wasn't thorough, say so
in the Verdict's reasoning rather than implying more confidence than was earned.

---

## Rules

- **No invented rigor.** The Verdict is exactly one of Proved / Disproved / Unresolved — no
  confidence percentage, no "high confidence," no probability estimate. That is the same
  discipline [`proof-of-value`](../proof-of-value/SKILL.md) applies to invented numbers, and
  it applies here to invented certainty.
- **Disproved requires an actual counterexample**, concrete enough to run or trace by hand —
  not "this seems like it could fail under load."
- **Unresolved is a legitimate, valuable verdict, not a failure of the skill.** It means the
  claim needs a stronger lemma, a different technique, or genuinely isn't provable at this
  level of formality — all real findings. Route it back to whoever owns the code, not smoothed
  into a soft Proved.
- **A Proved verdict is re-checked whenever the code or the Formalization changes.** A stale
  Proved attached to code that has since moved is a false signal, not a saved step.
- **Mechanized tooling, when it genuinely exists and is actually run, corroborates — it does
  not replace — the Proof and the Attempted refutation.** If an SMT solver, a property-based
  test framework, or a model checker was actually invoked, cite exactly what ran and what it
  found. Never describe what a tool "would" show without running it.

---

## Worked example

Claim: *reversing a list twice returns the original list* — `reverse(reverse(xs)) == xs`.

```markdown
# Correctness proof: reverse(reverse(xs)) == xs for any finite list xs

## Formalization

- Objects and state: `xs` a finite list of arbitrary elements; `reverse` defined by
  `reverse([]) = []`, `reverse(x:xs) = reverse(xs) ++ [x]`.
- Claim: for all finite lists `xs`, `reverse(reverse(xs)) = xs`.
- Unbounded?: Yes — quantified over lists of arbitrary length.

## Lemmas

1. `reverse(ys ++ [x]) = x : reverse(ys)` for any list `ys` and element `x` — proved by
   structural induction on `ys` — used in step 2 of the Proof.

## Proof

1. Base case: `xs = []`. `reverse(reverse([])) = reverse([]) = []ss`. Holds.
2. Inductive step: assume `reverse(reverse(xs)) = xs` (IH) for a list `xs` of length n.
   Consider `x:xs` of length n+1. `reverse(x:xs) = reverse(xs) ++ [x]`. Applying `reverse`
   again: `reverse(reverse(xs) ++ [x])`. By Lemma 1 with `ys = reverse(xs)`, this equals
   `x : reverse(reverse(xs))`, which by IH equals `x : xs`.
3. Therefore `reverse(reverse(xs)) = xs` for all finite `xs`, by induction on length.

## Attempted refutation

Checked the empty list (handled explicitly in the base case, not glossed over) and a
single-element list (`x:[]`: reverse gives `[x]`, reverse again gives `[x]`, matches).
Checked whether the inductive step's use of Lemma 1 actually needs `ys` finite — it does,
and `xs` is finite by the Formalization, so no gap there. No counterexample found.

## Falsifier

If `reverse` is later redefined for a lazy/infinite-stream type, this proof no longer
applies — finiteness is load-bearing in the base case and in Lemma 1.

## Verdict

Proved — the induction is over the list's own recursive structure, the hypothesis used
(`reverse(reverse(xs)) = xs`) is exactly the claim at one step smaller, which does close
(no strengthening needed here — a rare case where the direct IH is already inductive), and
Lemma 1 was independently discharged before being used.
```

This example is deliberately simple — a case where the direct induction hypothesis already
closes. Most real code needs the hypothesis strengthened first, per the table above; a proof
that skips stating that strengthening as its own lemma is the most common way this skill's
output collapses into confident, plausible prose.

---

## Where this connects to the rest of the skill set

- A claim inside a sprint ticket that is really an algorithmic-correctness question ("does
  this dedup logic actually work") is [`code-proof`](../code-proof/SKILL.md)'s job, not
  [`proof-of-value`](../proof-of-value/SKILL.md)'s — run this skill on that specific claim
  and cite its Verdict as one of `proof-of-value`'s Premises, tagged `source: code-proof`.
  `proof-of-value` proves a task's acceptance criteria discharge a plan's bar; it does not
  itself verify that an algorithm is correct.
- A claim genuinely too costly or high-stakes to close through reasoning alone — one that
  needs an actual model checker or proof assistant run against a full formal spec — is a
  finding for the user, per [`escalate`](../escalate/SKILL.md): say so, and say what running
  the real tool would cost, rather than reasoning in prose about what it would find.

---

## Out of scope

**Whether the claim is worth proving.** Choosing which property matters enough to formalize
is the caller's decision, or `proof-of-value`'s when the context is a sprint ticket. This
skill only proves the property once it has been chosen.

**Setting up and running a mechanized prover, model checker, or property-test framework as a
first-class deliverable.** Genuinely running one, when it exists and is asked for, is a
legitimate corroboration to cite in the Verdict — but it is not built by default, and this
skill's proof is never dependent on tooling that wasn't actually invoked.

**Confidence scores or probability estimates attached to a Proved verdict.** The verdict is
binary-plus-honest-third-option, not graded.

---

## Done when

The claim is one sentence and sharply bounded, not "this function is correct"; the
Formalization states objects, a precise predicate, and an explicit Unbounded yes/no; every
lemma is independently proved, names its own technique, and never restates the Claim; any
strengthened induction hypothesis appears as its own lemma rather than an unstated leap in
the Proof; the technique used matches the claim's shape per the menu, or the mismatch is
named as a finding; Attempted refutation documents a real search targeting the boundary case
and the "obvious" step, escalated to a separate agent for high-stakes claims; a Falsifier is
stated; and the Verdict is exactly Proved, Disproved with a real counterexample, or
Unresolved with the reason — never a claim quantified over an unbounded parameter marked
Proved without a valid induction or reduction closing it.
