---
name: mvp
description: Build software MVP-first — agree what the minimum version must do, sketch a rough plan of decisions and build order, implement the simplest thing that works, verify it with unit then integration tests at interactive checkpoints, strip it to something a human can read, then optimize toward a scalable design using measured evidence. Use whenever starting a new project, feature, or component from scratch, for research or proof-of-concept work where the shape of the problem is not yet known, when the user says "MVP", "get it working first", "barebones version", "proof of concept", or "iterate on this", or when a task would otherwise invite a large up-front design. This is the default development style; it is not for throwaway code.
---

# mvp

A development style, not an experiment. **The code written here is the code that ships.** It does not get thrown away — it gets simpler, then faster, then scalable, in that order, across the same files.

The reason to work this way is not speed. It is that requirements move, and a design chosen before anything runs is a guess that every later decision has to honour. Working code tells you where the real constraints are. Nothing else does.

Often the work is unfamiliar — research, a proof of concept, a technique not used here before. Then the unknown is not just the design but **the shape of the problem itself**: what the hard part turns out to be, which assumptions survive contact with real data, where the cost actually sits. Stage 2 exists to find that out by building the smallest real thing and watching it run. The robust system comes later, built on what was learned rather than on what was assumed.

## Stage 1 — Requirements

Write down what the minimum version must **do**. Concrete and checkable:

```
MVP must:
- ingest a .parquet file and yield batched records
- run end to end on the sample dataset without crashing
- print per-batch shape and dtype
Explicitly out of scope for the MVP:
- streaming, retries, config plumbing, multiple input formats
```

Rules for this stage:

- **Capabilities, not architecture.** What it does, never how it is structured. Module layout, class hierarchies, and design patterns are stage 3 decisions and are wrong to make here.
- **Keep it to a handful of lines.** If it is growing into a specification document, you have left this stage.
- **Write the out-of-scope list.** It is what stops stage 2 from sprawling, and it is where "we'll need this later" goes to wait its turn.
- Do not ask **the user** for a planning document or ticket. If one exists, mine it for the capability list and ignore the rest.
- **If the repo has a `SPEC.md`, the capability list may not contradict it.** Requirements there are the user's obligations on the system, not suggestions — read them, and if the MVP cannot meet one, raise it now rather than discovering it at stage 2. See [`spec-doc`](../spec-doc/SKILL.md); Claude never edits that file.

**Offer [`prior-work`](../prior-work/SKILL.md) once the capability list is agreed**, before the rough plan, while the approach is still free to change. Name what it costs — a few minutes of search — and let the user decide. It is an offer, not a gate, and a declined offer is a fine outcome. Skip it only when the thing being built is unambiguously specific to this repo. Surveying how others solved the problem *after* the shape is settled is how you discover the shape was wrong.

### The rough plan

Once the capability list is agreed and the open choices are settled, write it down: the list, the decisions and why they went that way, the components in build order with the checkpoint each stops at, and the one risk most likely to invalidate the whole thing. A page, not a specification.

This is not the architecture document this stage forbids. It records **what was decided and what is still unknown**, never how the code will be structured. The test: every line is either a capability, a settled choice with its reason, or a named uncertainty paired with the experiment that resolves it. Anything describing module layout or class structure has drifted into stage 3.

It earns its place three ways — it makes a wrong assumption visible while changing it is still free, it gives the user something to review instead of reconstructing the shape from a conversation, and when stage 2 contradicts it, the contradiction is legible because the original expectation was written down.

**Order the build so the cheapest disconfirming evidence comes first.** If one component can prove the approach unworkable, it goes before every component that assumes it works.

**Then turn the list into a tracked todo list** with `TaskCreate` — one task per component to build, plus a task for the 2.5 strip pass and one for stage 3 on each component. Mark a task `in_progress` when you start it and `completed` only once its tests pass, and keep it current as you go. This is the user's live view of where the work is: it shows the whole shape of the MVP at a glance, makes the checkpoints in stage 2 visible before they arrive, and gives somewhere concrete to move an item when scope is cut rather than losing it. Add tasks as new components surface — discovering work is expected here, not a planning failure.

## Stage 2 — Make it work

The simplest implementation that satisfies the list. **It has to work, not work well.**

Simple is not the same as sloppy. The target is the shortest path a reader can follow end to end — flat, direct, obvious. Messiness is not permitted; it just isn't cleaned up until 2.5.

Two constraints govern this stage:

- **Small enough to hold in one head.** The user must be able to read the entire MVP and understand all of it quickly. That is not a nicety — it is what lets them judge whether the shape is right. If it has outgrown that, the capability list was too long: say so and cut it rather than pressing on.
- **Work in the open, one component at a time.** Do not build the whole thing and present it finished. Stop at each component, report, and wait. The user is reviewing the *shape of the problem*, not just correctness, and a wrong shape caught at the second component costs almost nothing to fix.

Rules while building:

- **Build components in isolation first, then join them.** Get each major piece running on its own with real inputs before wiring anything together. Then connect them through their interfaces and print what crosses each boundary. Integration failures are interface information — they are the main thing this stage buys you.
- **Run it constantly.** After every meaningful piece, execute it and read the actual output. Report real output, never what it should have printed. Code that has not run has proven nothing.
- **Every module runs on its own.** Put a `__main__` at the bottom that exercises the module against real input and prints what it produced. It is how a component gets verified before anything depends on it, and it keeps earning its place afterwards as the fastest way to see what the module actually does — faster than reading it, and it cannot go stale the way a comment does.
- **Hardcode freely.** Paths, thresholds, model names — inline, with a comment marking what will need lifting later.
- **Environment and test command exist before the first component.** A reproducible environment file, and a test runner that executes an empty suite green. It costs two minutes at the start and is the difference between a project someone else can run and one they cannot.
- **Flat over abstract.** No base classes, no dependency injection, no strategy objects, no premature helpers. One function that does the thing beats three that arrange to do the thing.
- **No error handling beyond what keeps it running.** Never `try`/`except` around something you don't yet understand — the crash and its traceback are the fastest description of your problem you will get.

### Testing in stage 2

Tests here answer **"does this work?"**, not "is this interface right?". That distinction is what makes them worth writing before the design has settled: they verify a component so the next one can be built on it, and they are cheap to delete when an interface moves.

**Unit tests first, per component.** As soon as a component runs on real input, write small tests for the behavior the capability list named, plus anything the run surprised you with. Name each after the behavior it checks. One behavior per test, no loops or conditionals re-implementing the logic. Run them, show the output, and do not proceed to the next component until they pass — an unverified component becomes an unverified assumption that everything downstream inherits.

**Integration tests once components are joined.** Test each seam with real data crossing the real boundary, and assert on what actually arrives — shapes, types, counts, the values themselves. This is where the shape of the problem usually reveals itself, because the mismatch between what one component promises and what the next needs is the thing nobody predicts on paper.

**Unit tests live in `tests/`, integration tests in `tests/integration/`.** Split them by what makes them fail: a unit test goes red when one component's behavior changes, an integration test goes red when an interface between two of them moves. Keeping them apart means a red run localises the problem before you have read a single line — component or seam — and it lets the fast suite stay fast while the slow one earns its runtime.

Keep the suite proportionate to the MVP: a handful of tests per component, readable in a sitting. Coverage is not the goal — confidence that each piece does what you think is. When an interface moves, rewrite the affected tests without ceremony; a stage 2 test is not a contract and defending it against a better design gets the priority backwards.

Never weaken an assertion or wrap failing code in `try`/`except` to get to green. A passing suite that proves nothing is worse than a failing one, because it is believed.

This is the **exploring** stage from [`coding-standards`](../coding-standards/CODING_STANDARDS.md). Locked-in rules are silent, and raising them against stage 2 code is itself a finding. Two blocking rules still hold, because they are what makes the output trustworthy: **fail fast and loudly**, and **errors carry the offending value**.

Stage 2 is done when the capability list runs end to end, every component has passing unit tests, every seam has a passing integration test, and the user has seen enough to describe the shape of the problem in their own words. Not when it is good.

## Stage 2.5 — Make it readable

A **subtraction-only** pass. Nothing is added here: no features, no abstractions, no optimizations, no tests. If the diff introduces anything, it belongs in another stage.

Delete:

- Comments that narrate what the code already says. Keep only the ones explaining *why* — a non-obvious constraint, a rejected alternative, a workaround for someone else's bug.
- Dead code, unused imports and parameters, variables assigned and never read.
- Scaffolding that existed to get it running: debug prints that no longer earn their line, commented-out attempts, leftover experiments.
- Duplication that has become obvious now that the whole thing is visible.
- Any abstraction with exactly one caller. It is not yet an abstraction; it is indirection.

Then improve names — this is the cheapest moment in the project's life to fix them — and update the stage 2 tests to match. Re-run the whole suite afterwards: it is what proves this pass removed only weight and not behavior. Tests are not exempt from the delete list either; the same narration comments and dead scaffolding accumulate there.

Do this **before** optimizing, not after. You cannot see a bottleneck through bloat, and every line removed here is one that never has to be profiled, ported, or maintained. The exit condition is that a human can read the whole thing top to bottom and describe what it does.

## Stage 3 — Make it scale

Now, and only now, design.

- **Measure before changing anything.** Profile or time the real path on real input and record the numbers. Optimizing without measurement is up-front design wearing different clothes — it just arrives later in the timeline.
- **Let the measurement pick the target.** Fix the largest cost first. State what you expect the change to buy, then re-measure and report the actual before/after. A change that didn't move the number gets reverted, not rationalized.
- **Apply patterns where the code has asked for one.** A pattern earns its place when there is a second real caller, a boundary that has already had to change twice, or a demonstrated cost. Not because a shape is familiar.
- **Harden per module, not all at once.** A module is locked-in when its interface has survived two changes without moving — the definition in [`coding-standards`](../coding-standards/CODING_STANDARDS.md). Once it is, the locked-in tier binds: schema validation on config, real error boundaries, injected time and randomness, type coverage.
- **Promote the tests.** The stage 2 suite proved the components work; now the interfaces have stopped moving, so tests can pin down contracts worth keeping. Harden them here: edge cases the measurement exposed, boundaries, malformed input, duplicates, and the failure modes found while building. A stage 2 test was cheap to delete; a stage 3 test is meant to outlive the next refactor.
- **Recipes go in `scripts/`, not into the modules.** Once the components work, the runs built on top of them — a sweep, an ablation, a data-prep pass, a demo, a one-off investigation — are thin compositions of the public surface, and they live in `scripts/` where nothing imports them. This is what stops "just one more flag" from accreting onto a component that had a clear job: a recipe that needs different behavior composes the pieces differently instead of adding a parameter. It also makes the public surface honest, because a recipe can only reach what the module actually exposes.

## Reporting

At the end of a stage, report in this shape:

```
## <stage> — <component or feature>

**State:** <what runs now, in one sentence>
**Evidence:** <actual command output, or before/after numbers in stage 3>
**Surprises:** <what contradicted the expectation>
**Next:** <the single next stage or component>
```

Lead with anything that disproved an assumption. That is the highest-value output of working this way, and it is worth nothing if it arrives late.

**Before reporting a stage complete, if the change touched more than one file, run [`consistency`](../consistency/SKILL.md).** A stage that renamed something, changed a default, or moved a boundary has almost certainly left stale references behind — and they are cheapest to fix now, before the next stage builds on them.

## Moving between stages

Say which stage you are in whenever it is not obvious, and never silently skip one — going from a working MVP straight to design patterns is the failure this style exists to prevent. Stage 3 on one module while another is still at stage 2 is normal and expected; modules mature at their own pace.

Going backwards is a legitimate result. If stage 3 measurement or a changed requirement shows the shape is wrong, return to stage 1 for that component with what you now know. That is the loop working, not a setback.
