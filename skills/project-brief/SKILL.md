---
name: project-brief
description: Write and maintain the repository's auto-loaded context file (CLAUDE.md or equivalent) — the few hundred words every session starts with. Covers what belongs in it, what never does, and the rule that a result obliges an update. Use when initialising a repository, when a run or decision changes what the file asserts, when a rule has been broken twice and should be written down, when the file has grown past a page, and whenever a session discovers something a fresh session would otherwise re-derive. Also use when the user says the context file is stale or wrong.
---

# project-brief

Every session in a repository starts by reading this file, and no session chooses to. That makes
it the highest-leverage document in the project and the most expensive one to get wrong: a stale
claim here is not ignored, it is **believed and acted on**.

It answers exactly one question: *what does someone need to know before touching this repository
that they cannot get from reading the code?*

## What belongs

Five kinds of content, roughly in this order:

| Section | Holds | Test for inclusion |
|---|---|---|
| **What this is** | the project's purpose in a few sentences, and what is currently being attempted | a newcomer could otherwise misread the repo's goal |
| **Current state** | where the work stands, dated, with pointers | a fresh session would otherwise assume the wrong starting point |
| **Environment** | the interpreter, the env name, the invocation, hard resource limits | getting this wrong wastes a run |
| **Load-bearing rules** | rules whose violation has already cost something, each with its cost | breaking it silently is how the project fails |
| **Conventions** | where records go, how things are named | a session would otherwise invent its own |

**Current state is the section that earns the file.** A fresh session with no state paragraph
either re-derives what has been tried or, worse, repeats it. Name what exists, what has been
measured, and what is blocked — in a handful of lines, with pointers rather than detail.

## What never belongs

| Content | Why not | Where instead |
|---|---|---|
| Run results, tables of numbers | rot on the next run, and there are always more | `journal/experiments.md` |
| The reasoning behind a finding | belongs in a story that is read start to finish | `journal/notes.md` |
| The ordered list of what to do next | one owner only, or the two disagree silently | the plan document |
| Narrative history of the project | a fresh session needs the current state, not the path to it | git log, and the journal |
| Anything derivable by reading the code | costs attention on every session for no gain | nowhere |

The test: **if a fresh session would act differently for not knowing it, it belongs. Otherwise
it is costing every future session attention.**

## A result obliges an update

This is the rule the file exists to enforce and the one most often missed, because **nothing
edits the file when a result invalidates it.** A diff-driven check cannot catch it: the run
touched no line of the brief, and the brief now asserts something false.

So the trigger is not "did I edit this file" but:

> **Did anything I learned change what a fresh session should believe?**

Ask it whenever a step closes, a falsifier fires, a plan is superseded, or a measurement
contradicts an assumption. In practice this means the brief is updated in the *same* piece of
work that produced the result — not later, because later is when it is forgotten.

A brief that says *"nothing is built yet"* after two days of building, or quotes a baseline that
has since been measured differently, has done active harm: every session that read it started
from a false premise.

## Load-bearing rules carry their cost

A rule with no cost attached reads as a preference and gets traded away under pressure. A rule
with a number attached does not:

```markdown
1. **Gates are a hard constraint, never a positive reward term.** Trip a gate → 0. A weighted
   gate is farmable: 506 of 635 corpus failures were the single length gate, so the cheapest way
   to raise the score is padding strings.
```

Two further rules about the rules:

- **A rule earns its place after the second violation**, not the first. One mistake is a
  mistake; two is a pattern that documentation can prevent.
- **State the rule and the consequence, never the whole story.** The story lives in
  `journal/learnings.md`; the brief holds the one-line form that stops the mistake.

## Length

**Aim for one screen, accept two, never three.** The file is read in full at the start of every
session, so length is a tax paid repeatedly. When it grows past that, the cause is almost always
one of:

| Symptom | Fix |
|---|---|
| Results have accumulated | move to the journal, keep one dated line of state |
| The rule list keeps growing | the oldest rules are now obeyed by habit or enforced by tests; cut them |
| It narrates the project's history | replace with current state; history is in git and the journal |
| It duplicates the plan's next steps | delete; point at the plan instead |

Cutting is safe: anything removed is either in the journal, in the plan, or in git.

## Out of scope

The plan's ordered steps and decisions — [`plan-doc`](../plan-doc/SKILL.md). The written record
of runs and reasoning — [`notes`](../notes/SKILL.md). Where files live —
[`repo-layout`](../repo-layout/SKILL.md). Code style — 
[`coding-standards`](../coding-standards/SKILL.md). Harness configuration such as hooks and
permissions is a settings concern, not a brief concern.

## Done when

The file opens with what the project is and a dated current-state paragraph; the environment
section is sufficient to run something without guessing; every rule names the cost that bought
it; no run result, reasoning narrative or next-step list appears; nothing in it is derivable from
reading the code; it fits in one or two screens; and it was updated in the same piece of work as
the most recent result that changed what a fresh session should believe.
