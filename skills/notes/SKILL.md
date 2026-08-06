---
name: notes
description: Keep a project's written record — notes.md for reasoning and brainstorming, learnings.md for traps that cost time, experiments.md for the run log. Use whenever a result needs interpreting, a surprise needs recording, an idea is worth keeping for later, or the user says "note that", "record this", "add to notes", "write this down". Also use when a claim is being made about a project and it is not clear which experiment produced it.
---

# notes

A project accumulates three kinds of knowledge, and they rot at different rates. Keeping
them in one file means the useful part is unfindable; keeping them in three means each has
a shape that fits what it holds.

| file | holds | ordered |
|---|---|---|
| `notes.md` | interesting things to note and brainstorming — what results *mean*, ideas worth keeping | **oldest first** |
| `learnings.md` | traps that cost real time — tooling, environment, infrastructure | by topic |
| `experiments.md` | the run log — what was run, what came out | **newest first** |

The test for where something goes: *notes.md* is what you would tell a collaborator about
the problem, *learnings.md* is what you would tell them to save them a day, *experiments.md*
is what you would show them to prove it.

### The boundary with the plan, in both directions

If the project has a plan document, the split is not a nicety — it is what keeps either file
readable. **Notes are not a place to re-decide things, and the plan is not a place to record
results.** The second half is violated far more often, because every result feels worth putting
where people will see it.

| Content | Home |
|---|---|
| What a run produced, with its numbers | `experiments.md` |
| What a result *means*; what changed because of it | `notes.md` |
| A trap that cost time | `learnings.md` |
| What was decided, and the reason | the plan |
| What is still unknown | the plan |
| That a step closed, and which way it went | the plan, as one row pointing back here |

The test in each direction:

- **Toward the plan:** if the text would need rewriting after the next run, it is a result and
  belongs in a journal file. A number is a result. *"We chose softmax because raw log-probability
  is length-biased"* is a decision and stays in the plan.
- **Toward the journal:** if the text settles a question rather than reporting one, it is a
  decision. Recording it only in a note means the next session re-argues it.

Two failure modes worth naming, because one sentence of guidance does not prevent them:

- **A plan that accumulates result sections** grows until nobody reads it, and then constrains
  nothing. Watch for a heading named after one specific step — that is the tell.
- **Two documents both numbering things** collide silently, because each reads consistently on
  its own. **Steps are numbered in the plan only**; a queue here orders and annotates them and
  never invents its own.

See [`plan-doc`](../plan-doc/SKILL.md) for the plan's shape.

## notes.md

### Oldest first, and never rewrite history

`experiments.md` is newest-first because you want the latest result. `notes.md` is
**oldest-first because it is a story** — later entries revise earlier ones, and reading it
top to bottom is how someone reconstructs why the project believes what it believes.

When new evidence contradicts an earlier note, **append an update to that note; do not
delete it.** The superseded reasoning is the most valuable thing in the file: it records a
hypothesis that looked right and what killed it, which is exactly the trap the next person
will otherwise walk into.

```markdown
**Update from run 1 (below): the evidence has not supported this.** Memorisation-
reinforcement predicts held-out flat or falling; we saw it rise on every metric with
zero regressions. Still real, no longer the leading explanation.
```

### Every entry names the experiment it came from

This is the rule that makes the file trustworthy. A claim without provenance cannot be
re-checked, cannot be invalidated when the run behind it turns out to be broken, and
quietly becomes folklore.

```markdown
## pass@1 is a threshold metric, and it is hiding the learning

**2026-08-03 · from runs 1 and 2 (`key-gar` lr 1e-5, `tidy-stork` lr 1e-4)**
```

Date, then the specific run, script, or measurement. When a note comes from reasoning
rather than a run, say that too — "from reading the TRL source", "from arithmetic, not
measured" — because a reader needs to know which claims have been tested.

### Title the claim, not the topic

`## The learning rate was a real constraint, and 1e-5 was below it` — not `## Learning
rate notes`. A reader scanning headings should collect the project's actual conclusions
without opening anything. A heading that names a topic forces them to read the body to
find out whether there is a finding in it.

### Structure inside an entry

Claim as the heading, provenance line, the evidence that supports it — table or numbers,
not adjectives — then what follows from it. Keep the open question explicit where one
remains:

```markdown
**Open question:** is partial-credit progress *on the way to* solving problems, or is the
model getting better at the easy asserts of problems it will never solve? Those look
identical in aggregate.
```

An entry that ends in a stated open question is worth more than one that ends in a
confident summary, because the question is what the next experiment is for.

### Record what was ruled out, and how

Negative results and dead confounds belong here at full weight. "Difficulty mix does not
explain the gap — reweighting moves it 0.073 → 0.078" closes a line of enquiry
permanently, and without it someone re-checks the same confound in three weeks.

## Proposals

Keep candidate next steps at the **end of `notes.md`**, numbered, each with:

- what it changes
- **the hypothesis it tests**, stated so a result could contradict it
- the cost — GPU hours, implementation effort, or "free"

State the hypothesis *before* running, so it cannot be retrofitted to whatever happened.
A proposal that cannot be falsified is not an experiment, and noticing that at proposal
time is much cheaper than after the run.

Mirror the list into `experiments.md` as a short queue table so both files agree on
what is next; keep the reasoning in `notes.md` and let the queue link to it.

## learnings.md

Traps, not conclusions. Each entry: what happened, the metric or error that identified
it, and the fix.

**Headed with its date to the minute and the run it came from**, exactly as `notes.md` is.
A trap found during a named run is re-checkable; one attributed to nobody is not, and it is
the entry most likely to be quietly wrong later — the fix was version-specific, or the tell
only shows under that configuration. Where the trap came from a script or from reasoning
rather than a run, name that instead.

Two things earn their place beyond the fix itself:

- **The tell.** What distinguished this failure from a normal one — "`policy/entropy` 9.04
  against ~0.20 healthy; a flat reward alone reads as a model that cannot code".
- **The reasoning error, if there was one.** When a diagnosis went wrong before it went
  right, record the wrong turn and the evidence that should have prevented it. That is the
  transferable part; the fix itself is usually specific to one version of one library.

## Writing rules

**Numbers, not adjectives.** "assert_pass_rate 0.273 → 0.288 → 0.332, sign test p = 0.050"
rather than "results improved". Anything that cannot be written as a number gets its
uncertainty stated in words instead — "not distinguishable from this run alone".

**Say which comparisons are invalid.** If a metric is measured on a shifting subset, note
it where the metric is introduced. Otherwise the table reads as evidence when it is noise.

**Write it while it is fresh.** A finding recorded three days later loses the detail that
made it findable — the specific error string, the exact step where it turned. Record at the
moment the result lands, in the same session that produced it.

**Done when:** a reader can open `notes.md`, read top to bottom, and arrive at the
project's current understanding *and* know which parts are shaky — with every claim
traceable to the experiment that produced it, and every open question stated as a
question rather than smoothed over.
