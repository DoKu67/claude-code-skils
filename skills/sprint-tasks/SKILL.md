---
name: sprint-tasks
description: Decompose a plan document (a PLAN.md, PRD, design doc, or any written statement of a goal) into individual sprint tasks, each in a fixed ticket shape — user story, context, scope, requirements, acceptance criteria, Definition of Done, dependencies, references, delivery fields. Use when the user says "break this plan into tasks", "turn this into tickets", "decompose this into sprint tasks", hands over a plan/PRD and asks what the tickets look like, or asks for a backlog from a goal. Distinct from `plan-doc`, which owns the plan itself — this skill only reads it. Does not produce a formal justification/proof per task; that is a separate, not-yet-written skill.
---

# sprint-tasks

A plan says what the project is for and what happens next. It does not say what a person
picks up on Monday, reviews in one pull request, and closes by Friday. This skill is the
bridge: one plan goes in, a set of independently workable tickets comes out, each in the
same fixed shape so a reader never has to guess where the acceptance bar or the owner is
written down.

**This skill decomposes; it does not decide.** Every task's scope, requirement and
dependency must trace back to something the plan already says. If the plan is silent or
contradictory on a boundary a task needs, that is a gap in the plan, not a judgment call
for this skill to make quietly — see [Out of scope](#out-of-scope).

---

## The format

Every task uses this shape, unchanged in section order and headings:

```markdown
# [Outcome-focused title]

## User story

As a [type of user], I want [capability], so that [benefit].

## Context

[Why this is needed and what problem it solves.]

## Scope

In scope:
- [...]

Out of scope:
- [...]

## Requirements

- [...]
- [...]
- [...]

## Acceptance criteria

- Given [context], when [action], then [observable result].
- Given [context], when [action], then [observable result].
- Errors and edge cases: [...]

## Definition of Done

- All acceptance criteria pass.
- Code is reviewed and merged.
- Appropriate automated and manual tests pass.
- Accessibility, security, and performance requirements are met.
- Documentation, analytics, and release notes are updated where applicable.
- The change is deployed to [environment].
- No unresolved critical defects remain.

## Dependencies and constraints

- [...]

## References

- Design:
- Technical specification:
- Related issues:

## Delivery

- Owner:
- Priority:
- Estimate:
- Sprint:
- Parent epic:
```

**Every heading appears in every task, in this order, even when a section is short.** A
missing *Out of scope* reads as "nothing was excluded" when it usually means nobody thought
about the boundary.

---

## Before the tickets: a manifest

Produce a manifest table before the individual tasks, so the batch can be scanned before
anyone reads eleven tickets end to end:

```markdown
| Task | Parent plan step | Depends on | Priority |
|---|---|---|---|
| Rate-limit the public API by API key | Next step 2 | — | High |
| Add a 429 response with Retry-After | Next step 2 | Rate-limit the public API by API key | High |
| Emit rate-limit metrics to the dashboard | Next step 2 | Rate-limit the public API by API key | Medium |
```

The manifest is what makes the dependency graph visible at a glance and catches the two
failure modes early: a task with no parent step (scope invented, not decomposed), and two
tasks silently claiming the same in-scope item.

---

## Where each section's content comes from

Read the plan; do not invent what it does not say.

| Plan content | Feeds into |
|---|---|
| The objective / problem statement | Context, and the benefit clause of User story |
| Constraints | Dependencies and constraints, and any Requirement they force |
| Next steps (or equivalent deliverables list) | The set of tasks — one step commonly becomes 1–4 tasks |
| Decided | Requirements and Context — settled reasoning is restated, never re-argued |
| The plan's own out-of-scope items | Inherited into each task's Out of scope, never contradicted |
| Open questions | Dependencies and constraints, flagged as blocking until resolved — never silently resolved here |

If the input isn't in this repo's [`plan-doc`](../plan-doc/SKILL.md) shape — a PRD, a design
doc, a paragraph of goals in a message — the same mapping still applies: find the
problem statement, the constraints, and the list of deliverables, and decompose from those.

---

## Splitting a plan step into tasks

A plan step is strategy; a task is a unit of execution. They are not required to be 1:1.

- **A task must be independently shippable and reviewable** — one pull request, one review,
  one deploy (or safely behind a flag). If a step already reads like that, it becomes one
  task; padding it into several to look thorough is not the goal.
- **Prefer a vertical slice over a horizontal layer.** A thin end-to-end capability (e.g.
  "an authenticated user can reset their password by email") ships and demonstrates value on
  its own; "build the backend endpoint" and "build the frontend form" as two tasks usually
  cannot ship independently of each other, so avoid that split unless the plan itself already
  separates them for a reason it states.
- **When a dependency between tasks is unavoidable, name it** — in that task's Dependencies
  and constraints, and in the manifest's Depends on column. Do not leave it implicit in
  ordering alone.
- **No fixed cap on the count.** [`plan-doc`](../plan-doc/SKILL.md) caps next steps at three
  or four because that is strategy, written under uncertainty. A task list is downstream
  execution detail once a direction is settled, so it follows the work. If one plan step
  produces more than about eight tasks, say so — it is usually a sign the step is really an
  epic and should be named as this batch's Parent epic rather than split further.

---

## Rules that keep a task from being vague

Each of these mirrors a rule elsewhere in this skill set — specificity over vagueness, in
every field that invites a placeholder:

- **A user story names a real actor, not "a user."** If the plan's actor is a system (a CI
  pipeline, a cron job, an on-call engineer), name that system. A generic actor means the
  plan was not read closely enough to find the real one.
- **Every Out of scope line names something a reader would otherwise assume is included.**
  "Out of scope: mobile" is only useful if a reader would otherwise expect mobile.
- **Every requirement has a matching acceptance criterion, and vice versa.** An orphan
  requirement is untested; an orphan acceptance criterion is testing something nobody asked
  for.
- **"Errors and edge cases" names a real one**, surfaced from the plan's constraints or from
  the task's own failure modes — never left as the literal placeholder text, and never
  "handle errors gracefully."
- **`[environment]` in the Definition of Done is filled in**, from the plan or by asking —
  never left as a literal bracket.
- **Estimate and Sprint are sourced from the plan or written `TBD`, never invented.** A
  guessed estimate is worse than an absent one, because it reads as a commitment nobody made.
- **Priority may be inferred from the plan step's position** (earlier next-steps are
  higher-priority), but say so is inferred if there's no explicit priority in the plan —
  don't present a guess as a fact from the source.
- **Parent epic matches the plan's step name or number.** This is the one field that closes
  the loop back to the plan — per [`plan-doc`](../plan-doc/SKILL.md), only the plan numbers
  steps, so a task refers to that number rather than inventing a competing one.
- **References → Related issues lists sibling tasks from the same batch**, so the set is
  traceable to itself, not just to the plan.

When a scope boundary is genuinely ambiguous in the plan — not merely unwritten, but
unresolvable without a decision only the user can make — stop and ask, per
[`escalate`](../escalate/SKILL.md), rather than guessing which side of the line the task
falls on.

---

## Example

Plan excerpt (from a `plan-doc`-shaped `PLAN.md`):

```markdown
## Next steps
1. Rate-limit the public API per key, 429 with Retry-After, so far-below-quota tenants
   never notice. Falsifier: p99 latency for compliant callers regresses more than 5ms.
```

Resulting task:

```markdown
# Public API requests are rate-limited per API key

## User story

As a third-party integrator calling the public API, I want my requests capped and clearly
signaled when I exceed my quota, so that a runaway client of mine can't take down the
service for every other tenant.

## Context

The API has no per-key limit today; one misbehaving integration has twice degraded
p99 latency for all tenants (see Next step 1 in PLAN.md). This task adds the limit and the
signal a well-behaved client needs to back off.

## Scope

In scope:
- Per-API-key request counting on the public API gateway.
- A 429 response with a `Retry-After` header when a key exceeds its quota.

Out of scope:
- Configurable per-tenant quotas (single global quota for this task; see Next step 3).
- Rate-limit metrics on the dashboard (separate task, see manifest).

## Requirements

- Requests are counted per API key over a rolling 60-second window.
- A key over quota receives HTTP 429 with a `Retry-After` header in seconds.
- Compliant callers (under quota) see no added latency beyond the counting overhead.

## Acceptance criteria

- Given a key under its quota, when it makes a request, then the request succeeds with no
  added latency beyond counting overhead.
- Given a key over its quota, when it makes a request, then it receives 429 with a
  `Retry-After` header.
- Errors and edge cases: a key with no requests in the last 60s resets to full quota; the
  counting store being unavailable fails open (requests are allowed, not blocked).

## Definition of Done

- All acceptance criteria pass.
- Code is reviewed and merged.
- Appropriate automated and manual tests pass.
- Accessibility, security, and performance requirements are met.
- Documentation, analytics, and release notes are updated where applicable.
- The change is deployed to production, behind a flag defaulting off.
- No unresolved critical defects remain.

## Dependencies and constraints

- Falsifier from the plan: p99 latency for compliant callers must not regress more than
  5ms — measure before merging the flag on.
- Depends on nothing; unblocks "Emit rate-limit metrics to the dashboard."

## References

- Design:
- Technical specification:
- Related issues: "Emit rate-limit metrics to the dashboard", "Add configurable per-tenant
  quotas"

## Delivery

- Owner:
- Priority: High (Next step 1 of 3)
- Estimate: TBD
- Sprint: TBD
- Parent epic: Next step 1 — Rate-limit the public API
```

---

## Out of scope

**A formal justification that a task is worth doing — a proof, mathematical or otherwise,
that it's the right unit of work — is not produced here.** That belongs to a separate,
not-yet-written skill. Until it exists, do not fabricate a justification to fill the gap;
the plan's own Objective and Decided sections already carry the reasoning for why the work
is worth doing, and this skill's job is only to reference that, not to re-argue it.

**Creating the tickets in a tracker** (Linear, Jira, GitHub Issues) is a separate step from
producing their content. Produce the tasks in this format first; create them in a connected
tracker only when asked.

**Re-deciding the plan's scope.** If decomposing a step reveals it's actually two unrelated
efforts, or the plan is missing a constraint a task needs, that's a finding about the plan —
fix the plan first, per [`plan-doc`](../plan-doc/SKILL.md), rather than silently patching it
at the ticket level.

**Estimating with any real rigor.** This skill writes `TBD` for anything not sourced from
the plan; it does not simulate a planning-poker session.

---

## Done when

A manifest table precedes the batch, naming every task, its parent plan step, its
dependencies and its priority; every task has all nine headings in order; every requirement
has a matching acceptance criterion and vice versa; Out of scope names things a reader would
otherwise assume are in; Errors and edge cases names a real one; `[environment]` is filled
in; Estimate and Sprint are sourced or `TBD`; Parent epic matches the plan's own step
numbering; References → Related issues lists sibling tasks from the batch; and nothing in
any task asserts a boundary, priority, or justification the plan doesn't support.
