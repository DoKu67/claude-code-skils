---
name: spec-doc
description: Own SPEC.md — the human-authored contract that says what the system must do, and the conformance tests that prove a module meets it. The spec is a gate, never a reward term: when a module fails a requirement, the code changes, or the human changes the spec, and no other exit exists. Use whenever writing or revising a spec or a requirement, whenever a module is being built or changed against one, whenever a conformance test fails, whenever an agent is tempted to edit a test to make it pass, and whenever another skill needs to know what a module is obliged to do. Also use when the user says "spec", "requirements", "what must this do", "does this conform", or asks whether a change is allowed to alter the spec.
---

# spec-doc

A spec is the answer to *"what must this system do, whatever else changes"*. It is not a
plan — the plan is the volatile route and it is rewritten constantly. It is not a journal —
the journal is what happened. **The spec is what we want to be true**, written by the human,
and the code's job is to satisfy it.

Which makes the spec a **gate**. The distinction is one this skill set already draws
elsewhere, about rewards: *a hard constraint is tripped or not tripped; a positive weight is
farmable.* A spec an agent may edit is a positive weight — the cheapest way to satisfy it is
always to lower it. A spec only the human may edit is a gate, and the only variable left to
move is the code.

Everything below follows from that one property.

---

## The invariant

> **A failing requirement has exactly two exits.**
>
> 1. **Change the code** so it genuinely meets the requirement.
> 2. **Change the spec** — *and only the human does this.*
>
> There is no third exit. Not editing the test, not narrowing the scenario, not skipping it,
> not reporting the failure as acceptable.

Claude may **draft** a spec, **propose** a change to one, **write** conformance tests for
review, and **argue** that a requirement is wrong. Claude may not **commit** any of those
changes on its own initiative. A drafted requirement is a proposal until the human accepts
it; the moment it is accepted it is a gate, including for the agent that drafted it.

This holds even when the requirement is obviously wrong, even when the fix is one character,
and even when the human said "just make the tests pass" — because *"make the tests pass"* is
satisfied by both exits and only one of them is what they meant. When exit 1 is genuinely
impossible, stop and raise a spec change request (below). Stopping is the correct outcome,
not a failure to finish.

---

## The shape

```markdown
# <NAME> — specification

**Status · <date> · <n requirements, k failing, m unbound>.**

## Requirement levels  the tree: which guarantee each requirement serves, plus the module map
## Purpose          what this system must do, in a paragraph a newcomer can read
## Requirements     R-1…R-n, each a SHALL sentence plus its scenarios, in numeric order
## Not required     behaviour deliberately excluded, with the reason
## Clarifications   [NEEDS CLARIFICATION: …] — open questions that block work
## Conformance      the table: requirement → module → test → status
```

All six sections appear even when nearly empty. `None` is a legitimate entry — an absent
*Not required* reads as "nothing was excluded" when it usually means nobody wrote down why.

*Requirement levels* comes **first, before Purpose**, because it is the only view that shows
what each requirement is *for*. Everything after it is read against that tree.

---

## Requirement levels

A flat list of requirements answers "what must be true" and hides "what breaks if this one
doesn't". Two requirements can look equally important on a flat list while one of them exists
solely to make the other true — and the day they disagree is the day that matters. The tree is
what makes that visible before it costs anything.

> **A level says what rests on a requirement, not how strongly it binds.**

Every requirement is an obligation at every level. There is no weak level and nothing is
optional lower down. Get this wrong and the section becomes a priority list, which is the one
thing it must not be — a "Level 3" nobody implements because it sounded minor is exactly the
failure the hierarchy exists to prevent.

- **Level 1** — a guarantee the system makes to a person. Nothing else in the spec exists to
  serve it.
- **Level 2** — an obligation a Level 1 guarantee rests on. Break it and its parent is
  unproven, however green the parent's own tests are.
- **Level 3** — an obligation a Level 2 requirement rests on, at one further remove.

Deeper than three is a sign the spec is modelling a call graph rather than a set of
obligations. Stop at three and use *also serves* notes for the rest.

### The tree

A fenced block, one line per requirement, module on the right. Children indent under the
parent they serve:

```
R-1   A run's whole life is recorded                        core.pipeline
├── R-7    The code that produced a run is recoverable       core.snapshot
└── R-8    A run is one deployment                           core.pipeline
    └── R-16  The deployed file is declared as configuration core.models

R-4   The record is append-only                              core.schema
└── R-6    The live database has every declared guard        core.db
```

- **Every requirement appears exactly once**, at its primary parent. A requirement serving
  more than one parent gets an *also serves* note in its byline, not a second line in the tree.
- **A Level 1 with no children is normal** and needs no apology — it means nothing else in the
  spec exists to hold it up.
- **A reserved number does not appear; a deferred one appears marked.** A reserved ID has no
  obligation to place. A deferred one has a real obligation that is not binding yet, and hiding
  it is how the gap gets rediscovered later — show it with `— DEFERRED` on its line.

### The module map

Read down a module's column to see every obligation it carries, and at which level:

```markdown
| Module | Level 1 | Level 2 | Level 3 |
|---|---|---|---|
| `core.pipeline` | `R-1` | `R-8` | `R-16` |
| `core.schema` | `R-4` | — | — |
| `core.db` | — | `R-6` | — |
```

A Level 1 entry is a guarantee that module owns outright; a Level 2 or 3 entry is one it owes
to the requirement above it. Where nothing is built yet, the column names the *planned
component* in the spec's own domain terms — never a filename, which would put implementation
back into the one document that must survive it.

### Name where the levels do real work

Close the section by naming the one or two parent/child pairs where the hierarchy earns its
place — the pair where the parent can be green while resting on nothing:

> `R-4` is what the record's immutability means, but a guarantee declared in the schema is not
> a guarantee the connected database makes. `R-6` is what makes `R-4` true in practice, so
> `R-4` green with `R-6` red is a claim resting on nothing.

This is the sentence a reviewer uses. Without it the tree is decoration; with it, a red child
is known to invalidate a green parent, and the conformance table stops being readable
row-by-row in isolation.

### What it changes downstream

- **Each requirement carries a byline** under its heading: its level, its module, the parent it
  serves, and any *also serves* note — `*Level 2 · `core.db` · serves `R-4` · applies it to the
  live database*`. This is what carries the hierarchy into the Requirements section, and it is
  why that section does not need rearranging to show it.
- **The Requirements section stays in numeric order, and so does the conformance table.** Both
  are lookups. The tree is the one place the structure lives; a document that also *orders* by
  it has two orderings of one list, which is how the two drift apart and how a reader loses the
  ability to find `R-13` by scanning.
- **Heading depth is uniform.** Every requirement at the same level of heading, scenarios one
  deeper. Depth cannot encode the tree once the section is in numeric order — a `####` child
  sitting above its `###` parent reads as a mistake — so the byline encodes it instead.
- **A requirement is still readable alone.** The byline names the parent; it does not assume the
  reader has just read it.

---

## A requirement

Two parts, always. The sentence says what must be true; the scenarios say how you would
check.

```markdown
### R-4 — Per-key rate limiting

The API SHALL reject requests that exceed the quota configured for their API key.

#### Scenario: quota exceeded
- GIVEN a key that has used its full quota this window
- WHEN a further request arrives on that key
- THEN the response is 429 and carries a Retry-After header

#### Scenario: quota resets
- GIVEN a key that was rejected in the previous window
- WHEN the window rolls over and a request arrives
- THEN the request is served normally
```

Rules that keep requirements human-readable, which is the whole point of writing them down:

- **One requirement, one behaviour.** If the SHALL sentence needs an "and" joining two
  unrelated obligations, it is two requirements.
- **A requirement stands alone.** If understanding R-4 requires first reading R-2, either
  merge them or restate the dependency in words.
- **SHALL for obligations, SHOULD never.** A requirement that is optional is not a gate. Put
  preferences in [`coding-standards`](../coding-standards/SKILL.md).
- **No implementation.** No tech stack, no schema, no function names, no file paths. A
  requirement that names a class is describing a design, and designs get replaced without
  the obligation changing. The [`mvp`](../mvp/SKILL.md) stage 3 owns design.
- **A human must be able to check a scenario by hand.** If checking it needs a script, the
  scenario is describing a property, not an example — see
  [`test-plan`](../test-plan/SKILL.md), which owns the harder instruments.
- **Three scenarios is usually the ceiling.** More than that and the requirement is covering
  two behaviours, or the scenarios are enumerating inputs rather than distinguishing cases.

### Numbering

**The spec numbers requirements, and nothing else does.** The plan numbers steps
([`plan-doc`](../plan-doc/SKILL.md)); [`sprint-tasks`](../sprint-tasks/SKILL.md) numbers
tasks. Three namespaces, so always write the prefix: `R-3`, *step 3* and *Task 3* are three
different things and "3" alone is a collision waiting to be read wrong.

Requirement numbers are assigned once and never reused. A removed requirement leaves its
number retired, so an old commit message or test name that mentions `R-9` never resolves to
something else later.

---

## Clarifications, not guesses

When a spec is being drafted and something is underspecified, **mark it rather than deciding
it**:

```markdown
[NEEDS CLARIFICATION: does the quota window slide, or reset on a fixed boundary?]
```

The temptation is to pick the plausible default and move on, because the draft reads better
finished. But a guess written in the spec's voice is indistinguishable from an obligation
the human chose, and it will be enforced as a gate against every future change. **An open
clarification blocks any task that depends on it** — say so and stop, rather than building
against the guess.

---

## Conformance tests

One scenario is one test. That mapping is not a convention, it is what makes the spec
checkable without interpretation: a failure names a scenario, a scenario names a
requirement, and a human reading the failure knows immediately which obligation is unmet.

```
tests/spec/test_rate_limit.py

    def test_R4_quota_exceeded():        # GIVEN / WHEN / THEN, verbatim, as comments
    def test_R4_quota_resets():
```

- **Named for the requirement.** `test_R4_…` so a red suite reads as a list of unmet
  obligations, not a list of broken functions.
- **Obvious over clever.** No shared fixtures doing hidden setup, no parametrised matrices,
  no assertions on internals. The test should be readable by whoever wrote the requirement,
  including in six months. A conformance test that needs explaining has failed at its job.
- **They live in one place** — a single directory, so "the conformance suite" is a path and
  not a judgment call about which tests count.
- **They are the floor, not the ceiling.** The spec suite proves the obligations are met.
  Everything else — edge cases, properties, regressions —
  is [`test-plan`](../test-plan/SKILL.md)'s territory and lives elsewhere.
- **Claude drafts them; the human owns them.** Same rule as the spec itself: a drafted test
  is a proposal, and once committed it is fixed.

---

## The gate is only a gate if the agent cannot move it

This is the section the skill exists for.

When a requirement fails, every one of the following makes the suite green without making
the requirement true. All of them are the third exit, which does not exist:

| Tell | What it looks like |
|---|---|
| **The test changed with the code** | Any diff to the conformance suite in the same change as the module it gates |
| **The assertion got looser** | `== 5` becomes `> 0`; a tolerance widens; an exact match becomes a substring |
| **The case disappeared** | A scenario deleted, skipped, xfailed, or commented out |
| **The subject got mocked** | The thing under test replaced by a stub that returns the expected value |
| **The input got special-cased** | The module branches on the scenario's literal fixture — passes the test, fails the requirement |
| **The failure got averaged** | New passing tests added alongside, and the result reported as "12 of 13 pass" |

**The checkable rule:** a pass only counts if the conformance suite is unchanged. Before
reporting that a module conforms, confirm the suite is byte-identical to the committed one —
`git diff --exit-code tests/spec/` — and say so. A green suite with a dirty spec directory
is not evidence of anything.

**And on the code side:** a scenario is an *example* of the requirement, never its
definition. The question is not "does it pass these two scenarios" but "would it pass a
third scenario the human could reasonably have written". If the answer is no, the module
does not conform, however green the suite is. Satisfying the letter of a scenario while
missing its obligation is the same failure as reward hacking, and it is caught the same
way — by checking the held-out case, not the trained-on one.

---

## When the code genuinely cannot meet the spec

Exit 2. Stop, and hand the human a decision in a shape that is cheap to answer — the
[`escalate`](../escalate/SKILL.md) message shape, specialised:

```markdown
## Spec change request — R-4

**Requirement, verbatim:** The API SHALL reject requests that exceed the quota configured
for their API key.

**Why the code cannot meet it:** one or two sentences, concrete.

**Evidence:** the failing scenario, the run, the measurement — a pointer, not a paragraph.

**Proposed replacement:** the requirement as it would need to read.

**What that stops guaranteeing:** the obligation the change gives up. This is the part the
human is actually deciding.

**Status:** awaiting decision. No code or spec changed.
```

Do not edit `SPEC.md`. If the request will outlive the session, record it under the plan's
*Open* section as one line pointing here — plans already own unknowns, and a request parked
in scrollback is a request nobody answers.

---

## The conformance table

One table, kept in `SPEC.md`, so the state of the gate is visible without running anything:

```markdown
| Req | Module | Test | Status |
|---|---|---|---|
| R-1 | `api.limiter` | `test_R1_default_quota` | ✅ |
| R-4 | `api.limiter` | `test_R4_quota_exceeded`, `test_R4_quota_resets` | ❌ |
| R-7 | — | — | unbound |
```

`unbound` is the row that earns the table: a requirement with no module and no test is an
obligation nobody has taken on, and it is invisible in every other view. ✅ and ❌ differ in
shape as well as colour, so the table survives being printed or read by someone who does not
distinguish red from green.

---

## The three documents

| Content | Home |
|---|---|
| What the system must do, whatever else changes | **the spec** |
| What we are doing next, and what would falsify it | the plan — [`plan-doc`](../plan-doc/SKILL.md) |
| What a run produced, and what it meant | the journal — [`notes`](../notes/SKILL.md) |

The test, when it is not obvious: **would this sentence still be true if the plan were thrown
away and the project restarted from scratch?** If yes, it is a requirement. If it would need
rewriting after the next run, it is a journal entry. Otherwise it is a plan entry.

A *Decided* entry in the plan that describes **system behaviour** rather than a working
choice has outgrown the plan — promote it to a requirement and leave a pointer. "We chose
softmax over raw log-probability because raw is length-biased" is a plan decision. "Scores
SHALL be length-invariant" is a requirement.

---

## Optional: make the rule enforceable

The invariant above is a rule, and rules are followed by whoever remembers them. In a repo
where that is not enough, deny the edit outright:

```json
{ "permissions": { "deny": [
  "Edit(SPEC.md)", "Write(SPEC.md)",
  "Edit(tests/spec/**)", "Write(tests/spec/**)"
] } }
```

The attempt then fails instead of needing to be caught in review. The cost is real and worth
stating: the human must make every spec edit themselves, including ones they would happily
have delegated. Use it where the gate matters more than the convenience.
See [`update-config`](../update-config/SKILL.md) for where the file lives.

---

## Length

**A spec nobody rereads stops constraining anything**, exactly as a plan does. Signs it has
outgrown the format:

| Symptom | What it usually is |
|---|---|
| A requirement needing a paragraph | two requirements, or a design that wandered in |
| Scenarios enumerating inputs | a property — hand it to [`test-plan`](../test-plan/SKILL.md) |
| Rationale, alternatives, history | the plan's *Decided* or the journal |
| Requirements about how, not what | design; see [`mvp`](../mvp/SKILL.md) stage 3 |
| A tree deeper than three levels | a call graph, not a set of obligations — flatten it and use *also serves* |
| Every requirement at Level 1 | the tree was filled in mechanically; nothing was asked about what rests on what |

---

## Where this connects

- [`plan-doc`](../plan-doc/SKILL.md) — the plan's steps work toward requirements; the spec
  does not schedule anything.
- [`sprint-tasks`](../sprint-tasks/SKILL.md) — a ticket's `Satisfies` field names the
  requirements it makes true, by ID, and a sprint is measured by which requirements it turns
  green. It will not decompose a plan without a spec to decompose it toward.
- [`implement-feature`](../implement-feature/SKILL.md) and [`mvp`](../mvp/SKILL.md) — both
  find the requirement before building and verify against it after; definition of done is the
  conformance suite green with the suite unchanged, not "the code runs".
- [`test-plan`](../test-plan/SKILL.md) — conformance is the floor; sufficiency is its job.
- [`escalate`](../escalate/SKILL.md) — the spec change request is one of its triggers.
- [`consistency`](../consistency/SKILL.md) — a requirement renamed or retired ripples into
  test names, task references and the conformance table.

---

## Out of scope

Deciding **what the requirements should be** — that is the human's, and this skill will not
quietly decide it for them. Writing the module — [`implement-feature`](../implement-feature/SKILL.md)
or [`mvp`](../mvp/SKILL.md). Proving code correct beyond its scenarios —
[`code-proof`](../code-proof/SKILL.md).

---

## Done when

All six sections are present, with *Requirement levels* first; every requirement appears
exactly once in the tree, at no deeper than Level 3, carrying a byline naming its level, its
module and the parent it serves; the module map has a row per module and the section names the
pair where a green parent would rest on a red child; the Requirements section and the
conformance table are both in numeric order, with heading depth uniform and the hierarchy
carried by the bylines; every requirement is one SHALL sentence
with at least one Given/When/Then scenario a human could check by hand; no requirement names a
technology, file or class; every underspecified point is a `[NEEDS CLARIFICATION: …]` marker
rather than a guess; requirement IDs are prefixed and never reused; every scenario has exactly one
conformance test named for its requirement; the conformance table shows a row per
requirement with `unbound` where nothing has taken it on; no spec or conformance test was
edited by Claude without the human accepting it; any pass reported was reported alongside a
clean diff of the conformance suite; and anything the code could not satisfy left a spec
change request rather than a lowered gate.
