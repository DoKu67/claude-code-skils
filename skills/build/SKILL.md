---
name: build
description: "Build software whose requirements are known — new code or a feature in an existing codebase — as one loop: requirements, a feasibility check on each one, a plan, tickets whose independent pieces run as parallel subagents, then implement and test on the smallest input that exercises each path until every approved requirement passes, and only then test at full scale. The house coding rules apply to every line written and a sweep for stale references runs before any task or the whole build is called done. Use when the user runs /build, says \"build this\", \"implement this feature\", \"add this to the codebase\", \"MVP\", \"get it working first\", \"proof of concept\", hands over a ticket or a PLAN.md to be built, or asks for a measurement harness to be built. The default development style. Not for open questions whose answer would change the plan (can we do X, does X change Y); those are answered by running them before anything is built."
---

# build

Write and explain with ASD-STE100 at **90% compliance** as a writing target.
Apply the [writing rules](../report/SKILL.md#writing-style) to this skill's prose.

One entry point for building software whose requirements are known ahead of time. It covers
a new project, a new component, a feature added to an existing codebase, and an experiment
harness. **The code written here is the code that ships**: it gets simpler, then faster,
then scalable, in the same files.

**The assumption `build` rests on: every requirement it builds against is buildable.** It
does not investigate. When an item turns out to be a question ("can vLLM serve this model",
"does 8,192 beat 4,096") it stops and hands the item back to the user, who decides. It
never starts an experiment itself.

The test for which skill to use: **if every possible answer leads to the same next action,
build it; if some answer would change the plan, it is an experiment** —
[`experiment`](../experiment/SKILL.md), run by the user before or alongside this.

**Two things are never optional, whatever the input:**

- [`coding-standards`](../coding-standards/SKILL.md) applies **every time code is written**,
  including tests, scripts and harness code, while writing it and not as a pass at the end.
- [`consistency`](../consistency/SKILL.md) runs **on every task's diff before that task
  counts as done, and once more over the whole change** before the build is reported done.

Skipping either is skipping this skill, not a shortcut through it.

---

## Stage 0 — Route the input

Say which of these arrived, and whether the code is **new** (no codebase yet) or
**existing** (a codebase that already runs). Existing code changes Stages 3–4 below; nothing
else.

| Input | What happens |
|---|---|
| A goal or a feature described directly | Stage 1 drafts the requirements from it |
| A `PLAN.md`, PRD or design doc | Stage 1 mines it for requirements; Stage 3 uses it as the route |
| A sprint ticket (`Task N`) | Its `Satisfies` IDs are the requirements; its Acceptance criteria and Definition of Done are the bar. Confirm any blocking task is actually done, then go to Stage 3 |
| A harness request from an experiment | See [Building a harness](#building-a-harness); then Stage 1 |
| A bug report against a harness | Reproduce the failed check as a failing test first, then Stage 4 |

---

## Stage 1 — Requirements, minimized, approved

**Start from `SPEC.md`.** Everything built is built to make a requirement in it true.

1. **Draft or locate.** If the repo has a spec, find the requirement IDs this build
   targets and the ones it defers. If it has none, or the feature maps to no requirement,
   draft the missing ones in [`spec-doc`](../spec-doc/SKILL.md)'s shape: `R-n` SHALL
   sentences with scenarios, capabilities not architecture, plus an explicit *Not required*
   list. A first spec is small.
2. **Minimize.** Run [`minimal-cover`](../minimal-cover/SKILL.md) on the draft
   requirements. It returns the smallest set that still covers the user's goals, flags
   over-specific goals, tolerances and hard constraints, and lists what each remaining
   requirement alone covers. **Too many requirements is a defect**: the user must be able
   to read the whole list and change it.
3. **Approve.** The user approves or edits the minimized set. Claude never edits `SPEC.md`
   on its own authority; spec-doc writes the accepted version.
4. **Ambiguity is a question, not a guess.** A requirement with two readings gets a
   `[NEEDS CLARIFICATION: …]` and waits.

**Offer [`prior-work`](../prior-work/SKILL.md) once the requirements are agreed**, when the
thing is a technique not used here before and the approach is still free to change. It is
an offer, not a gate; a declined offer is fine. Skip it for work specific to this repo.

---

## Stage 2 — Feasibility gate

Before any plan is written, check the assumption this skill rests on. For each approved
requirement, decide whether its buildability can be settled by reasoning — an algorithmic
bound, requirements that cannot all hold together, "this interface can express X". If it
can, run [`code-proof`](../code-proof/SKILL.md) on the claim "R-n is satisfiable given the
other requirements and the stated constraints".

| Verdict | Action |
|---|---|
| **Proved** | Mark R-n buildable and continue |
| **Disproved** | Show the user the counterexample. They revise or drop R-n. Never build against it |
| **Unresolved, or only knowable by running** | **Stop and ask the user**, below |

Most requirements are ordinary ("the CLI accepts `--out`") and need no proof: mark them
buildable and say so in one line. The gate exists for the few that carry a hidden question.

When a requirement's buildability cannot be established, present it labelled **"this is a
hypothesis, not a known requirement"**, with one sentence on why, and ask:

- **Build anyway**: mark R-n *user-assumed* in the conformance table and continue. If it
  later proves impossible, that is the user's call surfacing, not a bug in the build.
- **Drop**: remove R-n from this build; it moves to *Not required* with the reason.
- **Rewrite, or run an experiment first**: pause R-n until `SPEC.md` changes. Offer a
  one-line hypothesis-card draft so starting an experiment costs the user one step.

The user may let the rest of the build continue while one requirement is paused. The gate
runs before planning, so stopping here costs nothing already built.

---

## Stage 3 — Plan the route

**Write the route with [`plan-doc`](../plan-doc/SKILL.md)**: what is decided and why, the
components or pieces in build order with the checkpoint each stops at, and the one risk most
likely to invalidate the whole thing. A page, not a design document: every line is a
capability, a settled choice with its reason, or a named uncertainty. Module layout and class
structure do not belong here.

**Order the build so the cheapest disconfirming evidence comes first.** If one piece can
prove the approach unworkable, it goes before every piece that assumes it works.

**Existing code: orient before planning.** Read the modules the feature attaches to. Name
the existing abstraction to extend rather than duplicate, the local conventions (naming,
layout, error handling), and every seam the new code crosses. Run the existing test suite
before changing anything, so a later failure is legible as caused by this change. Report
what exists, where the feature attaches, and the order the pieces will land in.

**New code: set up first.** A reproducible environment file and a test runner that runs an
empty suite green, before the first component.

**Decompose whenever pieces are independent.** When two or more pieces do not depend on
each other, or the work spans sessions, run [`sprint-tasks`](../sprint-tasks/SKILL.md) on
the plan: numbered tickets, each naming the R-ids it turns green, each with a Proof of value,
grouped into dependency waves. Confirm with the user which tickets, in what order. Only a
strictly serial chain skips it; then the plan's build order is the task list.

**Track it live** with `TaskCreate`: one task per piece, plus one for the readability pass.
Mark `completed` only when the piece's tests pass and its consistency sweep is clean.

---

## Stage 4 — Make it work, until every requirement passes

The loop, once per piece or ticket, in the planned order. **Pieces in the same wave run at
the same time**, one subagent each, as [`sprint-tasks`](../sprint-tasks/SKILL.md#running-the-waves)
says; each subagent runs steps 1–5 on its piece and the coordinator merges. Never work
through a wave one piece at a time in this session.

1. **Choose the tests** with [`test-plan`](../test-plan/SKILL.md) for the R-ids this piece
   serves: the cheapest instrument that genuinely checks each claim.
2. **Write the code under [`coding-standards`](../coding-standards/SKILL.md).** In new code
   the module is *exploring*: its Blocking rules hold, locked-in rules stay silent. In an
   existing codebase, locked-in modules in the touched area bind their locked-in rules now.
3. **Run it and read the real output.** Report what it printed, never what it should have.
4. **Sweep this piece's diff with [`consistency`](../consistency/SKILL.md)** before
   calling the piece done. Renames, changed defaults and moved boundaries leave stale
   references; they are cheapest to fix now.
5. **Tests green, then [`checkpoint-commits`](../checkpoint-commits/SKILL.md).**
6. **Stop and report**, then the next piece or wave. Never present the whole thing finished.

Loop until every approved requirement passes. Rules while building:

- **Minimal input until Stage 6.** Every run in this stage uses the smallest input that
  still exercises the path: 2 files, not 10,448; 2 workers, not 32 (two, so the parallel path
  still runs); one feature's page, not the whole site. The code may be built for full scale
  from the first line; only the run is small. Aim for a result the user can review within
  about five minutes, and shrink a run that would take longer rather than wait on it.
  Full-size and production-volume runs belong to Stage 6. *Why:* a 20-file smoke test and
  a two-hour full regenerate each delayed the first reviewable result; "do the minimal amount
  of work to test that it works so that we can get a mvp to test quickly." *Falsified if* the
  user asks for a full-size run before Stage 6, or minimal runs keep passing while full runs
  fail on correctness rather than scale.
- **Simplest thing that works.** Flat over abstract; no base classes, injection or helpers
  with one caller. Hardcode freely, marking what will need lifting later.
- **Small enough to hold in one head.** If it outgrows that, the requirement list was too
  long: say so and cut it rather than pressing on.
- **Pieces in isolation first, then join them.** Print what crosses each boundary;
  integration failures are interface information.
- **Every new module runs on its own**: a `__main__` that exercises it on real input.
- **Existing code: reuse before inventing.** A parallel path beside one that does almost
  the same thing is a cost to avoid. Use the existing environment and test runner as-is.
- **No error handling beyond what keeps it running.** The traceback is the fastest
  description of the problem. Fail fast and loudly; errors carry the offending value.

**Testing.** Unit tests per behaviour in `tests/`, named after the behaviour, one behaviour
per test, run before the next piece. Integration tests at every seam in `tests/integration/`,
asserting on what actually crosses. Existing tests must keep passing; a red test in untouched
code is a regression to fix now. Each acceptance criterion needs a test that could fail.
**Never weaken an assertion, edit a conformance test, or wrap failing code in
`try`/`except` to reach green.** A requirement the code cannot meet is a spec change request
for the user.

---

## Stage 5 — Make it readable

A **subtraction-only** pass: no features, abstractions, optimizations or tests added. Delete
narration comments, dead code, unused imports and parameters, debug scaffolding, obvious
duplication, and any abstraction with exactly one caller. Improve names. Re-run the whole
suite to prove only weight was removed. For anything past a light pass on existing code, run
[`code-tidy`](../code-tidy/SKILL.md). Done when a human can read it top to bottom and say
what it does.

---

## Stage 6 — Test at scale, then make it scale

**Run this stage whenever a requirement names a volume, a throughput or a deadline, or the
code was built to fan out**; skip it otherwise. Only after every requirement passes on
minimal input, rerun on the real volume — the full dataset, the full worker count, the whole
site — stepping up in size (10× at a time) so a failure points to the size where it began.
What breaks here is a scale bug — rate limits, memory, file-count and request limits,
stragglers, retries — and it is debugged here, not by going back to bigger Stage 4 runs.

- **Measure before changing anything**, on the real path with real input. Record the numbers.
- **Fix the largest measured cost first.** State what the change should buy, re-measure,
  and revert a change that did not move the number.
- **Patterns only where the code has asked**: a second real caller, a boundary that has
  changed twice, a demonstrated cost.
- **Harden per module** once its interface has survived two changes: locked-in rules bind.
  Promote the tests to contracts.
- **Recipes go in `scripts/`**, composed from the public surface, never as new flags on a
  component.

Every change here is still written under `coding-standards` and swept with `consistency`.

---

## Stage 7 — Verify and finish

1. **Walk every approved requirement**, pass or fail, not "looks good". Mark user-assumed
   ones as such. An unmet requirement is unfinished work unless the user defers it.
2. **Run the conformance suite** and report it alongside `git diff --exit-code` over the
   suite's directory. A pass counts only if the suite is unchanged.
3. **Run [`consistency`](../consistency/SKILL.md) over the whole change**, from `git diff`
   against the build's starting point: docs, config, fixtures and callers still describing
   the old world.
4. Report done only when every requirement is checked, the suite is green and unchanged, and
   the final sweep is clean.

---

## Building a harness

An experiment sends a **harness request**: the program it will run, taking one config,
running the system under test on fixed inputs, and writing one record per run. Turn its
six fields into ordinary requirements, then run Stages 1–7 like any build:

| Field | Becomes |
|---|---|
| Settings, with allowed values | R: `run(config)` works for every listed value |
| Fixed inputs | R: every run uses exactly these inputs |
| Measurements, with units | R: every run records each measurement |
| Record format (run ID, git SHA, harness version, config, raw outputs, measurements) | R: one record per run, append-only |
| Validity checks (known input gives the known answer; same config twice gives the spread) | R: both checks exist and pass |
| Out of scope | *Not required*, and not built |

Expose **one command** that takes a config and writes a record. Give the harness a version
and bump it whenever its behaviour changes. Build only what the request names: a setting or
measurement no approved card uses is out of scope. Reply with the version, the command and
the validity-check results.

A **bug report** names the failed check, the exact input and config, expected versus got,
and the harness version and run ID. Reproduce it as a failing test, fix it through Stage 4,
bump the version, and reply with the new version.

---

## Reporting

At each checkpoint:

```
## <stage> — <piece or feature>

**State:** <what runs now, in one sentence>
**Evidence:** <actual command output, or before/after numbers>
**Conformance:** <R-n pass / R-m fail / R-k user-assumed; conformance suite diff clean>
**Sweep:** <consistency: clean, or what it fixed>
**Surprises:** <what contradicted the plan>
**Next:** <the single next piece or stage>
```

Lead with anything that disproved an assumption; it is the most valuable output and is
worth nothing if it arrives late.

## Moving between stages

Say which stage you are in when it is not obvious, and never silently skip one. Going back
is legitimate: a measurement or a changed requirement that shows the shape is wrong returns
that piece to Stage 1 with what is now known.
