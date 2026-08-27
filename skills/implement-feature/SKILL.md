---
name: implement-feature
description: Implement one feature into an existing codebase — MVP-inspired but scoped to a codebase that already exists, so orientation replaces setup and integration replaces scaffolding from zero. Always applies coding-standards while writing and consistency before calling the change done. Accepts a sprint-tasks ticket (implements its Acceptance criteria and Definition of Done directly) or a plan (asks the user the questions needed to turn it into a sprint-tasks sprint first, with the same requirements, then implements that). Use when the user says "implement this feature", "add this to the codebase", "build this in", "wire this up", hands over a Task N ticket or a PLAN.md and asks for it built, or asks for a feature added to code that already exists. Distinct from `mvp`, which is for a new project, component, or codebase built from scratch — this skill is for extending one that is already there.
---

# implement-feature

`mvp` answers "how do we build this for the first time." This skill answers "how do we add
this to something that already runs." The difference changes almost every stage: there is no
environment to scaffold, no test runner to stand up, and no clean slate to build components
on in isolation — there is existing structure to read, existing conventions to match, and
existing tests that must keep passing.

**Two things are never optional, regardless of input shape:**
[`coding-standards`](../coding-standards/SKILL.md) applies continuously while code is being
written, not as a pass at the end, and [`consistency`](../consistency/SKILL.md) runs on the
finished change before it is reported done. Both are woven into the stages below; skipping
either is skipping this skill, not a shortcut through it.

---

## Stage 0 — Establish what's being built

What arrives determines how this stage runs. Identify which of the three before doing
anything else:

### Input is a sprint-tasks ticket

A `Task [N]` document in the [`sprint-tasks`](../sprint-tasks/SKILL.md) shape. Its
**Acceptance criteria** and **Definition of Done** *are* the spec — do not re-derive a
capability list from scratch or re-negotiate its Scope. Read Context and Dependencies and
constraints for the reasoning behind the boundary, then go straight to Stage 1.

If the ticket's Dependencies and constraints names another task as a blocker, confirm it is
actually done (code present, its own acceptance criteria demonstrably passing) before
starting — implementing against an unfinished dependency produces work that has to be redone.

### Input is a plan

A `PLAN.md` in the [`plan-doc`](../plan-doc/SKILL.md) shape, a PRD, or any written statement
of a goal that has not been broken into tasks yet. **Do not implement straight from a plan.**
A plan is strategy — What and Why at the level of a whole direction — and jumping from that
directly into code is exactly the gap `sprint-tasks` exists to close.

Instead:

1. **Ask the user the questions `sprint-tasks` needs answered before it can decompose
   responsibly.** Per that skill's own rule, a scope boundary the plan leaves ambiguous is not
   a judgment call to make quietly — it is a gap to ask about, per
   [`escalate`](../escalate/SKILL.md). Concretely, check the plan has (or get from the user):
   - A **Next steps** list, or an equivalent set of deliverables, to decompose.
   - Enough of **Constraints** and **Decided** to write real Requirements and Dependencies,
     not placeholders.
   - Answers to anything in **Open** that a task this sprint would depend on.
   - Which next step(s) — or how much of one — this implementation pass is actually meant to
     cover. A plan can name three next steps; the user may want only the first built now.
2. **Run `sprint-tasks` on the result**, producing the manifest, the parallel execution plan,
   and the full ticket(s) — same requirements, same fixed shape, nothing abbreviated. This is
   not optional scaffolding; it is where the acceptance criteria this implementation will be
   checked against get written down.
3. **Confirm the resulting ticket(s) with the user before writing code**, especially when the
   manifest produced more than one task or more than one wave. Get an explicit answer to "which
   task(s), in what order" rather than assuming "all of them, in manifest order."
4. Proceed into this same skill treating the confirmed ticket(s) as **Input is a sprint-tasks
   ticket**, above — one ticket at a time, in dependency order.

### Input is neither — a feature described directly

No ticket, no plan, just "add X." Run `mvp` Stage 1 exactly as written, but read it as scoped
to this feature rather than a whole project: a short, concrete capability list (what the
feature must do; what's explicitly out of scope for this pass), agreed with the user, small
enough to stay a handful of lines. Skip the `prior-work` offer unless the feature involves a
genuinely new technique this codebase hasn't used before — most features added to an existing
system are not that.

Do not write a rough plan or a build-order todo list here the way `mvp` Stage 1 does for a
whole project — for one feature, Stage 1 below (orientation) supplies the equivalent: where
it attaches, and in what order the pieces need to land.

---

## Stage 1 — Orient before writing anything

This is what replaces `mvp`'s from-scratch setup. Before any code is written:

- **Find where the feature attaches.** Read the modules it will touch or sit beside. Identify
  the existing interfaces it must respect, the existing abstraction it should extend or call
  rather than duplicate, and the existing tests already covering that area.
- **Find the local conventions**, not just the house rules in `CODING_STANDARDS.md` — naming,
  file layout, how errors are surfaced, how this codebase already solves the same kind of
  problem elsewhere. A feature that matches its neighbors is cheaper to review and cheaper to
  maintain than one that is locally "better" but foreign.
- **Name the seams**: every existing boundary the new code will cross — a function it calls
  into, a schema it writes to, a caller that will now receive a new field or a changed
  response. Each seam is where an integration test belongs in Stage 2.
- **Check what already passes.** Run the existing test suite (or the relevant slice of it)
  before changing anything, so a later failure is legible as caused by this change rather than
  inherited.

Report what you found before writing code, in the shape: what exists here, where this feature
attaches, and the order the pieces will land in. This is the checkpoint the user reviews
instead of `mvp`'s rough plan — same purpose, sized to one feature.

---

## Stage 2 — Build it in the open

The `mvp` Stage 2 rules apply, with the from-scratch ones dropped:

- **Work one piece at a time, in the order Stage 1 named**, and stop to report after each
  rather than presenting the whole feature finished.
- **Run it constantly** against real inputs and read the actual output, not what it should
  print.
- **Reuse the existing abstraction over inventing a new one.** `mvp`'s "flat over abstract"
  still holds for genuinely new code, but the first move here is checking whether the codebase
  already has the shape this feature needs — a new parallel path next to an existing one that
  does almost the same thing is a cost this stage should avoid, not create.
- **No environment or test-runner setup** — it already exists. Use it as-is; if it's
  inadequate for this feature, that's a finding to raise, not something to route around.
- **Apply `coding-standards` as you write**, not after. Locked-in modules in the touched area
  bind their locked-in rules immediately, not just at some later hardening stage — this is the
  one place `implement-feature` is stricter than `mvp` Stage 2, because the surrounding code is
  already past the exploring phase even when the new feature isn't.

### Testing

Same split as `mvp`: **unit tests per new behavior**, named after the behavior, run before
moving to the next piece; **integration tests at every seam named in Stage 1**, asserting on
what actually crosses the boundary. Additionally:

- **Existing tests must still pass.** A red test in code this feature didn't touch is a
  regression to fix now, not a pre-existing condition to note and move past.
- Tests for a ticket's own **Acceptance criteria** (when Stage 0 produced one) are not
  optional extras — each acceptance criterion needs a test that could fail if the criterion
  weren't met, by the time this stage is done.

Never weaken an assertion or wrap failing code in `try`/`except` to reach green — same rule,
same reason, as `mvp`.

---

## Stage 2.5 — Tidy

Subtraction only, same as `mvp` Stage 2.5: dead scaffolding, narration comments, obvious
duplication now that the whole feature is visible, any abstraction with exactly one caller.
For anything past a light pass — several files, or a change that grew larger than expected —
run [`code-tidy`](../code-tidy/SKILL.md) instead of redoing its checklist by hand.

---

## Stage 3 — Consistency sweep

**Mandatory, every time, run before reporting the change done.** Follow
[`consistency`](../consistency/SKILL.md) in full over everything this feature touched: stale
references to what the code used to do, docs describing the old behavior, other call sites
that should now use the new path, config or fixtures still shaped for the old one. A feature
added to a live codebase almost always has more than one place that assumed the old world —
this is the stage that finds them before a reviewer does.

---

## Stage 4 — Verify against the spec

Check the outcome against whatever Stage 0 established as the bar:

- **Sprint-tasks ticket**: walk every Acceptance criterion and every Definition of Done line
  explicitly — pass/fail, not a general "looks good." An unmet criterion is unfinished work,
  not a follow-up ticket, unless the user agrees to defer it.
- **Feature described directly**: walk the Stage 0 capability list the same way.

Only report the feature done once every criterion is checked, the consistency sweep is clean,
and the existing suite plus the new tests are green.

---

## Reporting

Same shape as `mvp`:

```
## <stage> — <feature or component>

**State:** <what runs now, in one sentence>
**Evidence:** <actual command output>
**Surprises:** <what the existing codebase's shape forced that Stage 0/1 didn't expect>
**Next:** <the single next stage or piece>
```

Lead with anything Stage 1's orientation got wrong once real code was written against it —
that is the equivalent of `mvp`'s "requirements move" and is worth surfacing immediately, not
folding silently into the diff.

## Moving between stages

Say which stage you're in when it isn't obvious. Never skip Stage 3 — it is the stage most
tempting to drop when the feature "obviously" works, and the one an existing codebase most
punishes skipping, because the damage lands in files this change didn't even touch.
