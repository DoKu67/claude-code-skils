---
name: test-plan
description: Decide what tests a piece of code actually needs — enumerate the claims it must satisfy, assign each the cheapest instrument that genuinely discharges it (unit test, integration test, property test, or a proof), then prove the set is sufficient by trying to construct a bug that passes every test in it. Use when the user asks what tests are needed, says "write tests for this", "what should I be testing", "is this well tested", "what's missing from these tests"; before writing tests for a new module, feature or change; and when a suite is green but nobody trusts it. Produces the plan and its proofs — writing and running the tests is the caller's next step. Distinct from `code-proof`, which proves one claim correct, and from `proof-of-value`, which proves a ticket's acceptance criteria discharge a plan's bar.
---

# test-plan

"How many tests should this have?" and "what coverage are we at?" are both the wrong
question, and they are wrong in the same way: they count instruments instead of counting
what the instruments are supposed to establish. A suite is not a quantity of tests. It is a
set of **claims** about the code, each paired with the cheapest instrument that actually
discharges it. This skill produces that pairing, and then tries to break it.

**The single rule that matters most:** a test discharges a claim only over the inputs it
actually runs. A claim quantified over an unbounded parameter — *for all inputs*, *for all
interleavings*, *for all N* — is not discharged by three examples passing, or three hundred.
Those claims go to [`code-proof`](../code-proof/SKILL.md), or they are honestly recorded as
checked at N ≤ k and no further. Nearly every "the tests were green and it broke anyway"
story is this rule being skipped: a bounded instrument silently read as an unbounded
guarantee.

---

## The format

```markdown
# Test plan: [the unit, module, or change under test]

## Contract

- Under test: [file:symbol granularity — what this plan covers]
- Stage: exploring | locked-in
- Real vs substituted: [which collaborators are real, which are substituted, and which of
  the boundaries between them are seams this plan must cover]
- Out of contract: [behaviour deliberately left unspecified]

## Claims

| # | Claim (precise enough to fail) | Unbounded? | Stakes if wrong | Instrument |
|---|---|---|---|---|
| C1 | [...] | No | [...] | Unit T1 |
| C2 | [...] | Yes | [...] | Proof P1 |

## Test inventory

| ID | Claim | Level | Real collaborators | Given / When / Then | A failure here means |
|---|---|---|---|---|---|
| T1 | C1 | unit | none | [...] | [the diagnosis a red T1 hands you] |

## Proofs

[For each claim routed to code-proof: the claim, its Verdict, one line of consequence.]

## Sufficiency proof

**Discharges:** the Contract above — [the specific behaviour the suite is claimed to protect]

**Claim:** If every test in the inventory passes and every proof above holds, the Contract
holds.

**Premises:**
1. [...] — source: T1
2. [...] — source: code-proof P1
3. [...] — source: Assumption (unverified)

**Argument:**
1. [step]
n. Therefore, the Contract is satisfied.

**Attempted counterexample:** [a concrete bug that passes every test in the inventory — or a
stated reason none could be constructed]

**Falsifier:** [what would invalidate this plan later]

**Verdict:** Proved | Conditional on [assumption] | Open — the missing test is: [...]

## Not tested, by decision

| Claim | Why not | What would change that |
|---|---|---|
```

Every section appears every time. A plan missing *Attempted counterexample* is a list of
tests someone felt like writing.

---

## The instrument menu — five, picked by the claim's shape

Each instrument is sound in its home domain and silently produces false confidence outside
it. Name the claim's shape before picking, exactly as
[`code-proof`](../code-proof/SKILL.md) does for proof techniques.

| Instrument | Fits when | Fails when |
|---|---|---|
| **Unit test** | The claim is about one unit's behaviour over a bounded, enumerable set of inputs, and the whole claim is observable at that unit's own interface | The claim is really about a seam (two units agreeing); the claim is unbounded and a handful of examples get read as *for all*; every collaborator is substituted and the assertion lands on the substitute — then the only thing discharged is the test's own wiring |
| **Integration test** | The claim is about a seam — a real boundary (database, filesystem, network, container runtime, scheduler, another service) where the failure mode is *disagreement* rather than logic | Reached for because the setup was easier, producing a slow unit test; or every dependency is faked, so the boundary the claim is about is never crossed |
| **Property / fuzz test** | An invariant holds over an input space too large to enumerate, is checkable without restating the implementation, and inputs can be generated | Its result is reported as "holds for all inputs" — it samples a space it cannot exhaust; or the oracle is the function's own logic rewritten, which passes by construction |
| **Proof** ([`code-proof`](../code-proof/SKILL.md)) | The claim is `Unbounded: Yes` and the stakes justify it — idempotence, no-data-loss, termination, race-freedom, "at most once" | The code is still moving, so the proof goes stale before it is read; or a cheap bounded check would settle the real risk just as well |
| **Untested, by decision** | The claim is real, but instrumenting it costs more than its stakes justify today | Used silently as the default — a claim that was never written down is indistinguishable from one nobody thought of, which is why this plan has a table for it |

**The checkable unit/integration boundary:** an integration test has at least one real
collaborator that could fail independently. Ask — if the real database, filesystem, network
or container were removed, would this test still pass? If yes, it is a unit test wearing a
costume, and the seam it was supposed to cover is still uncovered.

---

## Claims: precise enough to fail

- **A claim states an observable outcome, not an activity.** "Handles errors properly" is not
  a claim, because nothing could falsify it. "A 5xx from the store is retried three times,
  then raises `UploadFailed` with the last status attached" is.
- **Each claim gets `Unbounded: Yes | No` before an instrument is chosen**, using the same
  test as `code-proof`: is it quantified over input size, iteration count, thread or process
  count, recursion depth, or interleaving? This single column is what routes work to a proof
  instead of to a test that cannot close it.
- **Stakes decide what an unbounded claim gets.** An unbounded claim whose worst case is a
  wrong number in a log line gets a bounded check and an honest note. One whose worst case is
  data loss, duplicate billing, or a security boundary gets a proof — or gets escalated per
  [`escalate`](../escalate/SKILL.md) when neither is affordable.
- **One claim per test.** A test asserting three things reports one failure and hides the
  other two, and its name cannot describe what broke.

---

## Rules

- **No coverage percentage as a bar.** Line coverage measures which lines executed, not which
  claims were discharged; a suite at 100% can discharge nothing, and a suite at 40% can
  discharge every claim that matters. Cite coverage only as a gap-finder — "these branches ran
  in no test, is there a claim there?" — never as an exit criterion, and never as an invented
  target number.
- **A test whose assertion is on a mock discharges a claim about the mock.** `assert_called_with`
  establishes that your code called your substitute the way your test said it would. That is
  occasionally the actual claim (a seam contract); most of the time it is a claim about
  nothing, and it should be an integration test against the real boundary instead.
- **The oracle is written by hand or comes from a trusted reference — never from the code
  under test.** An expected value computed by restating the implementation's own logic passes
  by construction and fails only when the test is wrong.
- **A numeric bar is a claim like any other.** Its instrument is a benchmark with the number
  written down and asserted, and it belongs in the inventory. "It felt fast" discharges
  nothing, and an invented threshold is worse than no threshold.
- **Tests are named after the claim, not the function.** `test_upload` names the code;
  `test_retries_thrice_then_raises` names what breaks, which is what a red CI line needs to
  say.
- **Respect the stage gate.** Per [`coding-standards`](../coding-standards/SKILL.md), code
  that is still *exploring* gets contract-level tests only — pinning a moving interface with
  detailed unit tests buys nothing and taxes every subsequent change. Full inventories are for
  *locked-in* modules. When the stage is ambiguous, treat it as exploring.
- **A plan is re-derived when the contract changes.** A stale inventory attached to code that
  has since moved is a false signal, not a saved step — the same discipline both sibling
  proof skills apply to their own verdicts. Sweep for what the change should have touched per
  [`consistency`](../consistency/SKILL.md).

---

## The sufficiency proof: write the bug that passes

The last section is not a summary. Run [`proof-of-value`](../proof-of-value/SKILL.md) over
the inventory as a whole, with one adaptation: *Discharges* names the Contract rather than a
plan element, and the **attempted counterexample is a concrete bug that survives the entire
suite**.

This is where a test plan earns its keep. Listing tests is easy and feels productive;
constructing the defect that passes all of them is the only step that finds the hole. Its
verdicts carry `proof-of-value`'s consequences unchanged:

- **Proved** — every premise traces to a test in the inventory or a `code-proof` Verdict, and
  no surviving bug was found on a real attempt.
- **Conditional on [assumption]** — the argument is valid but leans on an unverified premise.
  That assumption is echoed into *Not tested, by decision* so it is visible downstream.
- **Open** — a bug that passes everything was found. The fix is to add the named missing test
  to the inventory and re-run the proof; never to narrow the Contract until the hole is
  outside it.

---

## Worked example

Code under test: `upload_once(path, key)` — uploads a file to an object store, retrying on
5xx, and must not write the object twice.

```markdown
# Test plan: upload_once(path, key)

## Contract

- Under test: storage/upload.py:upload_once
- Stage: locked-in — the signature has survived two changes
- Real vs substituted: object store is a real boundary (seam); the clock is substituted
- Out of contract: bucket creation, credential rotation

## Claims

| # | Claim | Unbounded? | Stakes if wrong | Instrument |
|---|---|---|---|---|
| C1 | A successful upload returns the object's URL | No | wrong link surfaced | Unit T1 |
| C2 | A 5xx is retried 3 times, then raises UploadFailed carrying the last status | No | silent data loss | Unit T2 |
| C3 | A real multi-MB file arrives byte-identical in the store | No | corrupt artifacts | Integration T3 |
| C4 | For any number of retries and any crash point, the object is written at most once | Yes | duplicate billing | Proof P1 |

## Test inventory

| ID | Claim | Level | Real collaborators | Given / When / Then | A failure here means |
|---|---|---|---|---|---|
| T1 | C1 | unit | none | Given a store returning 200, when uploading, then the returned URL matches the key | URL construction drifted from the key scheme |
| T2 | C2 | unit | none | Given a store returning 500 always, when uploading, then exactly 4 attempts occur and UploadFailed carries 500 | retry budget or error propagation broke |
| T3 | C3 | integration | object store, filesystem | Given a 5MB file, when uploading, then a re-read of the key is byte-identical | the seam disagrees — chunking, encoding, or content-length |

## Proofs

- P1 (C4): taken to code-proof. Verdict: **Unresolved** — the claim is quantified over crash
  points, and no induction closes it while the write and the ledger record are separate
  non-atomic steps. Consequence: routed back to the owner; a bounded crash-injection check at
  the three known crash points is recorded below as a partial substitute.

## Sufficiency proof

**Discharges:** the Contract — an object is uploaded correctly, or the caller is told it was not.

**Claim:** If T1–T3 pass and P1 holds, the Contract holds.

**Premises:**
1. Success returns the right URL — source: T1
2. Exhausted retries raise rather than return silently — source: T2
3. Bytes survive the real boundary — source: T3
4. At-most-once writing — source: code-proof P1 (Unresolved)

**Argument:**
1. Premises 1–3 cover the success path and the exhausted-failure path over the real seam.
2. Premise 4 is not established, so any step relying on at-most-once is unsupported.
3. The argument therefore cannot close.

**Attempted counterexample:** T3 generates a fresh key on every run, so no test ever uploads
to a key that already exists. A defect that appends to an existing object instead of
replacing it passes T1, T2 and T3 unchanged, and corrupts exactly the re-upload path that C4
is about. Found on first attempt; not an edge case.

**Falsifier:** if the write and the ledger record become one atomic operation, P1 is
re-provable and this verdict is re-run.

**Verdict:** Open — the missing test is T4: "Given a key that already holds an object, when
uploading, then the stored object equals the new file and no second object exists."

## Not tested, by decision

| Claim | Why not | What would change that |
|---|---|---|
| Uploads resume after process restart | No resume feature exists yet | The feature landing |
| Concurrent uploads of one key do not interleave | Unbounded over interleavings; needs a model checker, not a test | Concurrency becoming reachable from the public API |
```

Note what the counterexample did: it did not find a bug in the code, it found a bug in the
*plan* — three green tests that together leave the overwrite path uncovered. That is the
normal, valuable outcome, and it is invisible to any process that stops at listing tests.

---

## Where this connects to the rest of the skill set

- **[`code-proof`](../code-proof/SKILL.md)** takes every `Unbounded: Yes` claim this plan
  routes to it, and its Verdict comes back as a premise in the sufficiency proof. The two
  skills share one rule — bounded evidence never upgrades into an unbounded guarantee.
- **[`proof-of-value`](../proof-of-value/SKILL.md)** proves, at design time, that a ticket's
  acceptance criteria would discharge the plan's bar. This skill proves, at build time, that
  a suite would discharge the contract. When the code serves a sprint ticket, that ticket's
  acceptance criteria are the claim list's starting point — they arrive already falsifiable.
- **[`implement-feature`](../implement-feature/SKILL.md)** and
  [`mvp`](../mvp/SKILL.md) call this before writing tests, so the tests written are the ones
  the inventory names rather than the ones that were easy.
- **[`spec-doc`](../spec-doc/SKILL.md)** owns the conformance suite — one obvious test per
  `SPEC.md` scenario, and the floor this plan builds on. Those tests are the user's: they are
  a premise in the sufficiency proof, never an instrument this plan may reassign, weaken or
  fold into a parametrised case. A claim already discharged by a conformance test is marked
  as such and not re-tested here.
- **[`consistency`](../consistency/SKILL.md)** runs after a contract change to catch tests
  still asserting the old behaviour.
- **`run-triage`** owns a run that failed. This skill owns what should have been watching.
- **When the tests are eventually run, delegate the run to a subagent** and have it report
  pass/fail counts and the failing assertions only — test output is high-volume and low-value
  once a verdict has been reached.

---

## Out of scope

**Writing the tests, and running them.** The deliverable is the plan and its proofs — even
when the request bundles both in one sentence ("figure out what to test and write it"). The
inventory is what the caller writes tests from, in a separate, explicit step. Producing both
in one pass reliably degrades the plan into a description of whatever got written first.

**Whether the code is correct.** An Open sufficiency verdict says the suite has a hole, not
that the code has a bug. Proving the code correct is
[`code-proof`](../code-proof/SKILL.md)'s job; finding the bug is testing's, once the tests
exist.

**Choosing a framework, or wiring CI.** Follow whatever the repo already uses, per
[`coding-standards`](../coding-standards/SKILL.md)'s "the existing repo wins". A repo with no
framework at all is a question for the user, not a default to pick silently.

**Coverage tooling as a deliverable.** Coverage is consulted as a gap-finder inside this plan
and never configured, reported, or targeted as an outcome of it.

---

## Done when

The Contract names what is under test at file:symbol granularity and states its stage; every
claim is precise enough to fail and carries an explicit `Unbounded: Yes | No` plus its
stakes; every instrument was picked from the menu by the claim's shape, with every
`Unbounded: Yes` claim routed to a proof or honestly recorded as bounded-checked-only; every
integration test in the inventory has at least one real collaborator that could fail
independently; each test names one claim and states what its failure would diagnose; the
sufficiency proof documents a genuine attempt to construct a bug that passes the whole
inventory, and any Open verdict names the missing test rather than narrowing the Contract;
and every claim deliberately left uncovered appears in *Not tested, by decision* with what
would change that.
