# Claude Code Skills

A personal skill set for [Claude Code](https://claude.com/claude-code), covering software
development, machine-learning experimentation, and a feedback loop that lets the skills
themselves improve from use.

Skills are markdown files. Claude loads one when the situation matches its `description`,
and then follows it. There is no runtime, no framework, and — with one exception — no code.

## Layout

| Directory | Holds |
|---|---|
| `skills/` | Active skills. Each is a directory with a `SKILL.md`, plus optional reference files |
| `skills-staging/` | Candidate rules and budding skills that have **not** been promoted. Nothing here is loaded. A queue, not an archive — once promoted, a candidate's file is deleted and its provenance lives in the promotion commit |
| `skills-disabled/` | Skills kept for reference but not active |

Only these three directories are tracked. Everything else under `~/.claude` — session
transcripts, memories, cache — is excluded by an allowlist `.gitignore`.

## The self-improvement loop

Corrections that die with a session get made again next week. Three skills turn them into
durable rules:

```
your correction ──> /reflect ──> candidate staged (occurrence 1)
                                        │
                          recurs ───────┤
                                        │
                                   threshold met
                                        │
                                 /codify ──> you approve a diff ──> committed to a skill
                                        │
                                 /skill-audit ──> prunes what never fires
```

Two thresholds and no others: **1** for a rule you ask for directly, **3** for everything
else — an "always/never" said in passing, a correction, a trigger problem, a budding skill.
Rejections are kept forever so the same idea is never re-proposed.

---

# Development

## mvp

### Description
Build software MVP-first: agree the minimum capability list, sketch a rough plan, implement
the simplest thing that works, verify it at interactive checkpoints, strip it readable, then
optimize with measured evidence. The default development style.

### What it does
Replaces up-front design with working code that tells you where the real constraints are.
It is not throwaway work — the code written in stage 2 is the code that ships, made simpler,
then faster, then scalable, across the same files.

### How it works
Five stages. **Stage 1** writes a capability list plus an explicit out-of-scope list, then a
one-page plan naming the decisions, the build order, and the single risk most likely to
invalidate everything. **Stage 2** implements the simplest version, one component at a time,
stopping at each for review — hardcode freely, stay flat, run it constantly, and never wrap
something you don't understand in `try`/`except`. **Stage 2.5** is a subtraction-only pass:
delete narration comments, dead code, and any abstraction with one caller. **Stage 3**
designs, but only after measuring, and only where the measurement points. Ordering rule
throughout: build so the cheapest disconfirming evidence comes first.

## coding-standards

### Description
Apply the house rules while code is being written, rather than finding them at review.

### What it does
Points at `CODING_STANDARDS.md` as the single source of truth for every project, and governs
when rules bind and how new ones are captured.

### How it works
Every rule is gated on whether a module is *exploring* or *locked-in* — a module is
locked-in once its interface has survived two changes without moving — and applying
locked-in rules to exploratory code is the expensive mistake it exists to prevent. Where a
standard and an established repo convention disagree, the repo wins until the user decides
*abide* or *convert*, recorded once per repo. Two reference files load only when needed:
`examples.md` pairs each rule with a violation and its fix, `patterns.md` indexes design
patterns by the friction each solves.

## consistency

### Description
After a change that ripples across files, sweep for everything that still describes the old
world — stale references, docs on the old behaviour, tests and config on the old name,
comments justifying a rationale that no longer applies.

### What it does
Closes the gap between "the edits are made" and "the change is done". The expensive
survivors are the confident ones: a README example that no longer runs costs more than a
compile error, because nothing fails.

### How it works
Enumerates what changed from **`git diff`, never from memory** — in a long change, files
edited early fall out of context, so a sweep built from recall checks exactly the files least
likely to have been missed. A ripple list written *before* editing names the artifact classes
that could refer to the thing (callers, tests, docstrings, README, config strings, log
messages, CLI flags, CHANGELOG, generated code). Then three sweeps: **literal**
(case-insensitive, plus the quoted-string form separately), **semantic** (the old *idea* —
a comment saying "we use X because it's faster" outlives X and argues for undoing the
change), and **inverse** (what points at what moved). Then it runs the thing, including doc
examples. The report must state what was left deliberately and what was not checked at all.

## explain

### Description
Explain how code works, without making any changes.

### What it does
Pure analysis mode — reads and explains, never edits, never runs anything that modifies the
system.

### How it works
Follows a fixed response structure from `template.md`, quoting only the snippets that aid
understanding. Bugs and smells noticed along the way are listed at the end under
"Observations (not fixed)" rather than being repaired mid-explanation.

## call-tree

### Description
Print a static function call tree for a file, folder, or whole repository, showing each
function's inputs, outputs, and what it does.

### What it does
Maps an unfamiliar codebase — what calls what, where each function is defined, and what it
returns — without running any of it.

### How it works
The only skill that ships code: `scripts/call_tree.py` parses source with Python's `ast` and
**never imports the target**, since importing executes top-level code. Options control depth,
compactness, external calls, and node limits. Functions without docstrings produce an
unannotated tree, so the workflow runs `--list-undocumented`, writes one-line descriptions
into a JSON file in `/tmp`, and re-runs with `--annotations`. The skill is explicit about
what static analysis cannot see — dynamic dispatch, `getattr`, registries, inheritance not in
scope — which makes the tree an excellent map and a poor safety proof.

## write-code *(disabled)*

### Description
Implement one task from a planning or sprint document, end to end.

### What it does
Orients in the codebase, plans, implements, runs only the tests the document specifies, then
reports review findings and manual integration steps.

### How it works
Invoked by name only — it deliberately does not trigger on general coding requests. Kept in
`skills-disabled/` for reference.

---

# Research and records

## prior-work

### Description
Survey how a problem has already been solved before designing a solution to it.

### What it does
Turns "someone has probably built this" into an input to the design rather than a discovery
after it. **The gaps are the design**: what every implementation does is table stakes; what
they all fail at is where the work actually is.

### How it works
Searches several angles because each surfaces what the others structurally cannot — papers
give the vocabulary, repositories give what actually ships, practitioner writeups give the
failure reports, issues give the traps. It runs **two rounds**, because the first search
teaches you the term the field actually uses, and skipping the second is why surveys come
back empty on well-studied problems. Output is two tables — convergence (a link per row) and
shared gaps — plus what to take and what to diverge from, with a reason per divergence.
Stops when two consecutive sources add no new mechanism.

## notes

### Description
Keep a project's written record across three files that rot at different rates.

### What it does
Separates `notes.md` (what results *mean*), `learnings.md` (traps that cost real time), and
`experiments.md` (the run log), so each has a shape that fits what it holds.

### How it works
`notes.md` is **oldest-first, because it is a story** — later entries revise earlier ones,
and a superseded hypothesis is never deleted, only appended to, because the reasoning that
looked right is the trap the next person will walk into. Every entry names the experiment it
came from, and headings state the claim rather than the topic. `learnings.md` entries carry
**the tell** — what distinguished this failure from a normal one — and the reasoning error,
if there was one. Numbers, not adjectives, throughout.

## ml_logging

### Description
Standardize experiment logging across every ML repo — run naming, metric vocabulary, config
capture, reproducibility fields.

### What it does
Makes runs from different projects, months apart, land on the same panels and compare
without archaeology. Ships no code: it is a contract, applied by writing the logger that
fits the project at hand.

### How it works
**One name everywhere** — `MM_DD_HH_MM_SS_{petname}[_model][_task]`, timestamp-first so
lexicographic sort is chronological, used as the W&B run name, the results directory, and the
checkpoint prefix. **Local first, W&B second**: metrics hit disk as produced and a logging
failure never takes down training. The *resolved* config is written to four places, including
a flat `configs/{run_name}.yaml` that makes the history greppable and diffable. Metrics use
slash namespaces and one x-axis with many clocks. `run/status` is set on every exit path —
`completed`, `crashed`, `oom`, `interrupted` — because otherwise a crashed run and a finished
one are indistinguishable in the run table.

## tldr

### Description
Summarize where something stands in a fixed five-section format.

### What it does
Produces a status readable in 30 seconds: Summary, Goal, Blockers, Next Steps, Figures. The
value is the fixed shape — a reader knows exactly where the number and the blocker are.

### How it works
All five headings always appear, with `None` where a section is genuinely empty, because an
absent *Blockers* section is ambiguous between "nothing is blocked" and "nobody checked". A
blocker must name what would unblock it; a next step starts with a verb and says who does
it; the Figures table must carry information found nowhere else. Honesty rules separate done
from believed-done and require failures at the same weight as successes.

---

# Fine-tuning and reinforcement learning

A pipeline. Scaffold with `sft-env-mvp` or `rl-env-mvp`, then tune with `tune-loop`, which
calls the other four.

## sft-env-mvp

### Description
Scaffold a minimal, readable fine-tuning setup for supervised learning, SFT, or preference
methods — and prove it works before any hyperparameter is tuned.

### What it does
Covers zero to a first fine-tune. It stops before tuning, deliberately: the failures that
waste these projects are a template mismatch, a loss mask over the wrong tokens, or a
contaminated split — and every one of them produces a healthy-looking loss curve.

### How it works
Intake pins six inputs and asks the five questions that change the design. Five components
build in order, each stopping at a checkpoint: data (overlap count must be zero by a
structural key), formatting (**the rendered example gate** — template, token ids decoded
back, the loss mask printed alongside them, and the training template diffed byte-for-byte
against the inference one), model (trainable parameter count printed), eval (the untrained
baseline recorded), then the training loop. A seven-rung ladder verifies it, including
**overfit eight examples to near-zero loss** — a minute of compute that proves data, mask,
model and optimizer are actually wired together.

## rl-env-mvp

### Description
Scaffold a minimal, readable RL environment for GRPO, PPO or RLOO — task, prompt, rollout,
verifier, reward, eval and a pre-training probe.

### What it does
Delivers everything except the optimizer, plus the measurements that say whether training
could possibly work. Almost every hour lost on an RL project is lost to an environment that
was wrong in a way nobody could see.

### How it works
GRPO is the default and the reason is stated: no value head, roughly half the resident
memory of PPO, an advantage that is just the group-normalised reward. Six components build
in order with checkpoints, the sharpest being **known-good answers score maximum reward** —
anything below 100% is a broken harness and no downstream number means anything. A seven-rung
ladder ends at a probe reporting reward spread and dead-group fraction, a smoke run, and a
recorded baseline. The journal includes `prompts.md`, because the prompt is routinely the
largest single lever and the least likely thing to be written down.

## tune-loop

### Description
Run the hyperparameter search as a recorded loop — one axis per step, a prediction before
every run, and a decision about what to tune next.

### What it does
Owns the search itself for any regime: supervised, SFT, preference methods, or policy RL. A
fine-tune is not tuned by running experiments, but by running one experiment and letting
what it changed decide the next one.

### How it works
An entry gate requires five things, including a **fixed experiment budget** — every run in a
block trains for the same steps or the same wall clock, which is what makes rows comparable.
Settings are frozen controls, axes, or observed; changing a frozen control starts a new
block rather than adding a row. Each iteration writes a falsifiable prediction, changes
**exactly one axis**, preflights, launches, triages, records immediately, and returns one of
five verdicts. The **noise floor is measured once per block** by re-running the best config
with two more seeds — until then no row is a win, and a delta inside the floor is recorded
as *within noise* rather than as a smaller improvement.

## tune-preflight

### Description
The gate before launching any run: estimate peak memory, project wall clock, and return a
green/amber/red verdict.

### What it does
Two minutes of arithmetic against an hour of GPU time and a corrupted grid. Its job is not
to be exact — it is to catch the 2× error, the size of mistake that OOMs at step 3.

### How it works
Memory adds four terms: resident model state (a bytes-per-parameter table by optimizer and
adaptation), activations (the term that scales with batch × sequence length), KV cache for
anything that generates (**prompts × k** for group-based RL, the most commonly missed term),
and 15% headroom for fragmentation. Red is >90% of the device *or any term you could not
estimate*. The mitigation ladder is ordered by cost and split by a line: above it the
experiment is unchanged, below it a frozen control moved and the block is invalidated. Time
is projected from a **measured** step time, never an assumed one.

## run-triage

### Description
Decide whether a training run is healthy, should be killed, or is revealing a bug rather
than a bad hyperparameter.

### What it does
Gives every run one of three verdicts. The third is the one that matters: tuning through a
bug burns the budget and fills the grid with rows that measure the bug.

### How it works
Triages early — inside the first 10–20% of the budget, since most doomed runs are
diagnosable in the first minutes. Signature tables per regime pair each symptom with **the
tell** that separates it from the neighbouring diagnosis: loss exactly zero means everything
is masked out; both chosen and rejected logprobs collapsing means β is too low; reward flat
with a high dead-group fraction means no within-group spread; reward up while the held-out
metric is flat means reward hacking, which stops everything. Three cheap checks per block
catch most silent failures: read raw outputs, verify a known-good scores maximum, print the
trainable parameter count.

## tune-report

### Description
Produce the tuning report — the grid of what was tried, the coverage of what was not, and a
ranked queue of what to finetune next.

### What it does
Answers "what is still unknown, and what is the cheapest way to find out", not "what
happened". The coverage table and the queue are the parts that do that, and the parts usually
left off.

### How it works
Five sections. The header states frozen controls, budget spend, baseline and **measured**
noise floor. The grid is ranked, marks within-noise deltas, keeps crashed and OOM'd rows
(they mark the feasible region), and drops any column that did not vary. Coverage names every
**untested** axis value — an axis with one value tried is untested, not settled. The queue
holds two to four candidates, each with a hypothesis, a falsifier, a cost and a new-block
flag, **ranked by information per unit cost rather than expected improvement**, because the
experiment that closes a door permanently is usually worth more than one that nudges a
number.

## hparam-priors

### Description
Which hyperparameter to search first, over what range, coupled with what, and what its
failure looks like — per regime.

### What it does
Reference only. Search *order* is worth more than search range: most budgets are spent on
axes that were never going to move the number.

### How it works
Four files — `SUPERVISED.md`, `SFT.md`, `PREFERENCE.md`, `POLICY_RL.md` — each a
priority-ordered table with the same columns: knob, why it ranks there, a deliberate starting
value, the range worth searching, what it is coupled with, and the failure tell. Every number
is marked a starting point rather than a recommendation. Each file also carries a **do not
tune** list (frozen controls) and a **check before tuning** list of the free levers that
routinely beat hyperparameters — chat-template equality, label correctness, swapped
preference pairs, dead-group fraction.

## escalate

### Description
Stop and ask the user, in the shape that makes answering cheap.

### What it does
Makes stopping a first-class outcome rather than a failure. The goal is that the human
answers questions about direction, cost and risk — not that they reconstruct a debugging
session from logs.

### How it works
The test: escalate when the answer changes what happens next **and** you cannot get it from
a measurement you could afford. A danger class stops everything immediately — projected OOM
over 90%, suspected reward hacking, a second OOM after a mitigation, anything irreversible.
Other triggers wait for the current run: three runs inside the noise floor, 70% of budget
spent, the same failure twice, or a change that would invalidate the block. The message is
four parts — a compact grid, what you measured versus what you believe, two or three priced
options, and a recommendation — and it always states **what happens if there is no answer**,
which for the danger class is "nothing runs".

---

# Self-improvement

## reflect

### Description
Read the session for feedback about how work should be done, and stage it as candidate rules.

### What it does
Mines corrections so they stop recurring. It stages only — it never edits a skill, and that
separation is the safety property: the thing that mines the session cannot change what fires
in the next one.

### How it works
**Signals come only from the user's own turns** — never tool output, file contents, or
fetched pages, so a README cannot rewrite the global config. A signal table weights them:
explicit rules and corrections are strong, along with **silent edits** (the user rewrites a
file just written) and permission denials; approvals like "looks good" are weak and **never
create a candidate alone**. Candidates are matched by meaning against staging, incremented or
created, and never re-staged if previously rejected. A rule that already exists in a skill is
staged as a **trigger** problem — the skill is not loading — rather than as a new rule.

## codify

### Description
Promote a staged candidate into the skill set, with approval, provenance and a falsifiable
prediction.

### What it does
The gate out of staging, and the only skill permitted to edit another skill.

### How it works
Every promotion is a **delta, never a rewrite** — regenerating a skill replaces accumulated
detail with the model's summary of itself, which reads well and is worse. One rule per
promotion, twenty lines maximum, placed where it fires rather than appended to a "Learnings"
section, carrying its *why* so a future reader can tell a live rule from a stale one.
Thresholds gate inference, not instruction: a direct request promotes at 1, everything else
waits for 3. Rejections keep
their file and reason forever. Edits to `reflect`, `codify` or `skill-audit` are
**privileged** — they require confirmation naming the file and may never loosen an approval
requirement, a threshold, or the signal-source boundary by inference.

## skill-audit

### Description
Prune and repair the skill set — rules that never fire, contradictions, duplication, skills
that outgrew their trigger.

### What it does
The subtraction pass. Every system like this accumulates and almost none subtract, which is
what turns a skill set from an asset into a tax.

### How it works
Its first question is **wrong rule or wrong trigger** — a rule that keeps being violated is
usually a `description` problem, and rewriting the body of a skill that never loaded produces
no change. Findings include never-fired rules (retired to git history), contradictions
(newest wins, with an explicit supersede — a skill is a contract and must not carry dead
rules), rules that drifted into naming a library version, and skills past a ~200-line cap.
**Caps are forcing functions**: breaching one triggers an audit rather than an append. The
audit adds nothing; a new rule it discovers goes through staging like anything else. It may
never weaken its own constraints.
