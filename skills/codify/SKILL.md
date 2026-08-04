---
name: codify
description: Promote a staged candidate into the skill set — as a small delta to an existing skill, or as a new budding skill — with the user's approval, a provenance line and a falsifiable prediction. Use when the user runs /codify, when reflect reports a candidate has reached its threshold, when the user says "make that a rule" or "add that to the skill", and whenever a staged candidate is being accepted, rejected or reworded. It is the only skill permitted to edit another skill.
---

# codify

The staging area is where a rule proves it is a rule. This skill is the gate out of it.

Two properties make the gate worth having: **the user approves every promotion**, and
**every promotion is a delta** — a small addition or a small patch, never a rewrite. A
rewrite of a skill loses the accumulated detail that made it good and replaces it with the
model's summary of itself, which reads well and is worse. Add or patch; do not regenerate.

Staged by [`reflect`](../reflect/SKILL.md); pruned by
[`skill-audit`](../skill-audit/SKILL.md). House style for the writing itself:
[`coding-standards`](../coding-standards/SKILL.md) and the existing skills, which are the
style reference.

---

## The staging area

`~/.claude/skills-staging/` — a sibling of `skills/` and `skills-disabled/`, and
deliberately not a place skills load from. A candidate cannot affect a session until it is
promoted.

```
~/.claude/skills-staging/
    LEDGER.md                       # index: one line per candidate, newest first
    ask-before-new-dependency.md    # a rule delta
    tune-sanity/                    # a budding skill: a whole SKILL.md not yet promoted
        SKILL.md
```

### Candidate format

```markdown
---
id: ask-before-new-dependency
target: coding-standards          # a skill name, or `new`, or `new:tune-sanity`
kind: rule | trigger | new-skill
signal: explicit | correction | silent-edit | denial | revert | repetition
status: staged | promoted | rejected | superseded
occurrences: 3
threshold: 2                      # 2 for explicit rules, 3 otherwise
---

**Rule:** Ask before adding a runtime dependency; propose the stdlib version first.

**Prediction:** If this fires, dependency additions stop appearing in diffs unannounced.
**Falsified if:** the user asks for a dependency to be added without being consulted, or
reverses the rule.

**Occurrences**
- 2026-07-14 · session 86a561a4 · explicit · "don't pull in a package for this, write it"
- 2026-07-29 · session 33f0b2f3 · silent edit · requirements line deleted after commit
- 2026-08-03 · session 6a888c37 · explicit · "always check if the stdlib does it first"
```

Every occurrence carries a **verbatim quote and a session id**. That is the same provenance
rule [`notes`](../notes/SKILL.md) applies to findings, and for the same reason: a rule whose
evidence cannot be re-read becomes folklore, and folklore cannot be revised.

---

## Thresholds

| Candidate | Promotes at |
|---|---|
| **Direct request** — the user asks for a rule, in their own words, now | **1** — there is no inference to validate |
| Explicit rule — "always", "never", "from now on" | **2** occurrences |
| Everything else | **3** occurrences |
| Trigger problem (an existing rule that did not fire) | **1** — it is already a codified rule; only its trigger is being fixed |
| Budding skill | **3** occurrences *or* one deliberate trial the user judged useful |

The first time you hit something, learn from it. The second time, notice it. The third
time, codify it. Rules written after a single occurrence are usually right about the
instance and wrong about the class — the variations that the rule has to cover have not
been seen yet.

**Thresholds gate inference, not instruction.** They exist because a rule inferred from one
occurrence is usually right about the instance and wrong about the class. When the user
states the rule themselves there is no inference to be wrong, so waiting is pure delay — a
direct request promotes immediately, and the approval step still applies.

**A threshold is a floor, not a trigger.** Reaching it means the candidate may be
proposed; the user still approves.

---

## Promoting

### 1. Choose the surface

| Where it goes | When |
|---|---|
| **An existing skill** | The rule belongs to a job that skill already owns. Default — always prefer this |
| **A new skill** | Three or more related candidates target the same job that no skill owns, *and* that job has a moment it fires. A skill with one rule in it is a rule in the wrong place |
| **The skill's `description`** | It is a trigger problem: the rule exists but the skill did not load |
| **`CLAUDE.md` or project docs** | It is a fact about one project or one repo, not a way of working |

The test for a new skill is the **description**, written first. If you cannot write a
one-line trigger that says when it fires and how it differs from every existing skill, the
material belongs inside one of those instead. That is also the most common failure: a rule
put in a skill that never loads is worse than the same rule written nowhere, because it
reads as covered.

### 2. Write the delta

- **One rule per promotion.** Two rules is two promotions, each individually approvable and
  revertible.
- **Ten lines is the target, twenty is the ceiling.** A promotion that needs a section is a
  budding skill, not a delta.
- **Match the surrounding voice.** Same table conventions, same imperative register, same
  density. A skill that reads as two authors reads as unreliable.
- **State the rule *and* the why.** The why is what lets a future reader tell a live rule
  from a stale one. A bare imperative is unrevisable, because nobody can tell what evidence
  would overturn it.
- **Put it where it fires**, next to the related material — not appended in a "Learnings"
  section at the bottom. A rule filed by provenance instead of by topic will not be read at
  the moment it matters.

### 3. Show the diff and ask

The exact diff, the candidate's occurrence list, and the prediction. Then the user
approves, rewords, or rejects. Nothing is applied first and reported afterwards.

### 4. Record the outcome

| Outcome | Do |
|---|---|
| **Approved** | Apply the delta. Set `status: promoted`, add the promotion date and target file. Update `LEDGER.md`. Commit |
| **Reworded** | Apply the user's wording, verbatim. Record the original alongside it — the gap between what was inferred and what was meant is the most useful training signal this system produces |
| **Rejected** | Set `status: rejected` with the reason. **Keep the file.** [`reflect`](../reflect/SKILL.md) reads rejections and will not re-propose it |

**Rejections are kept forever.** A system that forgets what was rejected re-proposes it
every few weeks, which is how a helpful loop becomes an irritating one. The rejection
reason is also the sharpest description available of where the inference went wrong.

---

## Budding skills

A candidate too large to be a delta becomes a whole `SKILL.md` inside
`skills-staging/<name>/`. It is not loaded automatically — that is the point. To try it,
the user points at it deliberately for one session. If it earned its place, it moves to
`~/.claude/skills/`; if not, it stays staged or is rejected, and either way nothing was
running globally while the question was open.

A budding skill is promoted whole, once, with the same approval step. After promotion it is
an ordinary skill and later changes to it are ordinary deltas.

---

## Privileged edits

**`reflect`, `codify` and `skill-audit` are the loop that changes the loop.** A delta to
any of the three:

- must be stated as a meta-edit, naming the file and what constraint it changes
- requires explicit confirmation that names the file — not a general "yes, go ahead"
- **may never loosen an approval requirement, a threshold, a signal-source boundary, or a
  rejection record by inference from staged candidates.** Those change only when the user
  asks for the change directly, in their own words

A reflector that can lower its own bar will eventually lower it, and every rule promoted
afterwards inherits the doubt. The constraint costs nothing when the system is working and
is the only thing that helps when it is not.

---

## Version control

`~/.claude/` is a git repository tracking `skills/`, `skills-staging/` and
`skills-disabled/` and nothing else, and every promotion is one commit naming the candidate
id. That is the whole rollback story: a promotion that turns out to be wrong is
reverted, and the candidate returns to staging with the revert as evidence rather than
disappearing.

Commit message: `codify: <id> → <target skill>`, with the occurrence count in the body.

---

## Out of scope

Finding signals — [`reflect`](../reflect/SKILL.md). Deciding what to remove —
[`skill-audit`](../skill-audit/SKILL.md). Project-specific facts, which belong to
`CLAUDE.md` and memory rather than to a global skill.

---

## Done when

The candidate met its threshold and the user approved this specific diff; the delta is one
rule, under twenty lines, in the voice of its host, placed where it fires rather than
appended; it carries its why and its falsifier; the candidate file records the outcome with
the date and the target; a rejection kept its file and its reason; `LEDGER.md` is current;
the change is one commit; and any edit to `reflect`, `codify` or `skill-audit` was named as
a meta-edit and confirmed as one.
