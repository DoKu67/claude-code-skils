# Claude Code Skills

A personal skill set for [Claude Code](https://claude.com/claude-code), covering software
development, machine-learning experimentation, and a feedback loop that lets the skills
themselves improve from use.

Skills are markdown files. Claude loads one when the situation matches its `description`,
and then follows it. There is no runtime, no framework, and — with one exception — no code.

## Install

```sh
git clone git@github.com:DoKu88/claude-code-skils.git ~/.claude
cd ~/.claude
./install.sh
```

**Clone into `~/.claude`.** Claude Code reads skills from there and nowhere else; a checkout
anywhere else installs a working sync for skills that never load. If `~/.claude` already
exists, adopt it in place rather than cloning over it:

```sh
cd ~/.claude && git init && git remote add origin <your-fork>
git fetch origin && git checkout -f main
```

| Command | Does |
|---|---|
| `./install.sh` | Installs the sync timer and the hooks, then runs one sync to prove it works |
| `./install.sh --check` | Reports what is installed and when it last ran. Changes nothing |
| `./install.sh --uninstall` | Removes both timers. Leaves the repository and skills on disk |
| `./scripts/install-reflect.sh` | **Opt-in.** The 6-hourly pass that mines finished sessions — see [Mining sessions automatically](#mining-sessions-automatically) |

**The skills need no install step** — they work the moment they are on disk. `install.sh` only
sets up the background sync described under [Keeping machines in sync](#keeping-machines-in-sync),
so skipping it costs you the automatic push and nothing else.

The reflect pass is deliberately not part of `install.sh`: it spends model tokens and stages
rules without being asked, which should be a per-machine decision. `--check` reports it and
`--uninstall` removes it either way, because a timer the documented uninstall leaves running
is a trap.

If you are not the author of this repository, **fork it first** and point `origin` at your
fork. Otherwise the sync will commit correctly and fail at every push:

```sh
git remote set-url origin git@github.com:<you>/claude-code-skils.git
```

Requires `git`, `bash`, and either systemd (Linux) or launchd (macOS). Run `install.sh` once
per machine; it is idempotent, so re-running it after a `git pull` is safe.

## The skills

| Category | Skills | What the category covers |
|---|---|---|
| [Development](#development) | `mvp`, `coding-standards`, `consistency`, `explain`, `call-tree`, `write-code` *(disabled)* | Writing, reading and finishing code — the default build style, the house rules, and the sweeps that say a change is actually done |
| [Version control](#version-control) | `checkpoint-commits` | Keeping work safe as it is made, and deciding what shape the history ends up in |
| [Research and records](#research-and-records) | `prior-work`, `notes`, `ml_logging`, `tldr`, `report` | Finding out what already exists, keeping the written record of what was tried and what it meant, and turning any of it into a durable document |
| [Fine-tuning and RL](#fine-tuning-and-reinforcement-learning) | `sft-env-mvp`, `rl-env-mvp`, `tune-loop`, `tune-preflight`, `run-triage`, `tune-report`, `hparam-priors`, `escalate` | A pipeline: scaffold an environment, prove it works, then run the hyperparameter search as a recorded loop |
| [Self-improvement](#self-improvement) | `reflect`, `codify`, `skill-audit` | Turning corrections into durable rules, and pruning the ones that never fire |

## Layout

| Directory | Holds |
|---|---|
| `skills/` | Active skills. Each is a directory with a `SKILL.md`, plus optional reference files |
| `skills-staging/` | Candidate rules and budding skills that have **not** been promoted. Nothing here is loaded. A queue, not an archive — once promoted, a candidate's file is deleted and its provenance lives in the promotion commit |
| `skills-disabled/` | Skills kept for reference but not active |
| `scripts/` | Machine setup that must travel with a clone — the background sync, and the reflect pass (see below) |
| `hooks/` | Hook scripts, plus `hooks.json`, the tracked registration that `settings.json` cannot carry. See `hooks/README.md` |

Only these five directories are tracked. Everything else under `~/.claude` — session
transcripts, memories, cache — is excluded by an allowlist `.gitignore`. That allowlist is
also the safety property behind the sync: `git add -A` physically cannot stage a transcript
or a credential, because nothing outside the five is visible to git in the first place.

## Keeping machines in sync

A background timer commits and pushes skill changes every 6 hours, so edits made on one
machine reach the others without anyone remembering to push. It is installed **per machine**
by [`./install.sh`](#install), and the configuration lives in this repo so a clone carries it.

| File | Role |
|---|---|
| `install.sh` | The front door. Delegates to the two installers below |
| `scripts/sync-skills.sh` | The sync itself. Commits tracked changes, rebases on the remote, pushes. A no-op when nothing changed |
| `scripts/install-sync.sh` | Installs the timer — a systemd user timer on Linux, a launch agent on macOS. Idempotent; `--uninstall` removes it |
| `scripts/install-hooks.sh` | Merges `hooks/hooks.json` into `settings.json`. Called by `install-sync.sh`; run it directly after editing `hooks.json` |
| `hooks/edit-lock.sh` | Taken by the editor. Marks a session as actively editing |
| `hooks/session-end.sh` | Releases that mark and kicks a sync |

Three properties are deliberate.

**It never commits a file that is still being written.** A script cannot tell from the
outside whether a write is the last one — mtime says when a write happened, not whether
another is coming. Only the editor knows, so the editor marks it. Three layers, in order:

| Layer | Guards against | Mechanism |
|---|---|---|
| Sync lock | Two syncs interleaving `add`/`commit`/`rebase` | `flock`, non-blocking; `mkdir` fallback on macOS |
| Edit lock | Committing a file a session is still writing | `PreToolUse` hook marks the session; sync defers while any mark is live |
| Quiescence | Writers that take no lock — `vim`, scripts, other tools | Every changed file untouched for `QUIET_SECONDS` (120) before staging |

Deferring is cheap because release is prompt: `SessionEnd` drops the mark and immediately
kicks a sync, so a deferred run costs seconds rather than the six hours to the next slot.

**Every lock expires.** A mark older than `STALE_AFTER` (900s) is deleted and ignored, because
a session that crashes cannot release its own lock — and a lock nobody can release would stop
the backup forever, silently, which is the worst way for a backup to fail.

**It never destroys work**: no `reset --hard`, no `clean`, no `restore`, no force-push — when
a rebase conflicts it aborts, leaves the local commit intact and unpushed, and says so,
because a sync that resolves a conflict on its own is a sync that can silently lose an
afternoon. Deferring is likewise the safe failure: nothing is staged, so nothing is at risk.

**A missed run is caught at boot**: the timer is a calendar timer with `Persistent=true`, so a
machine that was powered off through a scheduled slot syncs on next boot rather than waiting
for the following one.

Check on it with `systemctl --user list-timers claude-skills-sync.timer` and
`journalctl --user -u claude-skills-sync.service` (Linux), or
`~/Library/Logs/claude-skills-sync.log` (macOS).

## The self-improvement loop

Corrections that die with a session get made again next week. Three skills turn them into
durable rules:

```
your correction ──> /reflect ──> candidate staged (occurrence 1)
                     ▲                  │
        every 6h     │    recurs ───────┤
                     │                  │
                                   threshold met
                                        │
                                 /codify ──> you approve a diff ──> committed to a skill
                                        │
                                 /skill-audit ──> prunes what never fires
```

Two thresholds and no others: **1** for a rule you ask for directly, **3** for everything
else — an "always/never" said in passing, a correction, a trigger problem, a budding skill.
Rejections are kept forever so the same idea is never re-proposed.

### Mining sessions automatically

`reflect` only ever ran when someone remembered to type `/reflect`, which is why no candidate
had accumulated across a session boundary. A timer now reads the sessions nobody reflected,
**every 6 hours at 05:30, 11:30, 17:30 and 23:30** — 30 minutes before each sync slot. Claude
Code does not need to be running: the timer is an OS-level scheduler that launches `claude -p`
headlessly, and `Persistent=true` covers the slots the machine was off through.

Six-hourly rather than daily because **a pass with nothing pending never invokes the model**.
It greps the transcripts, finds no new lines and exits, so cost tracks session volume rather
than timer frequency — the extra slots are close to free, and a finished session waits ~6h to
be mined instead of ~24h.

The 30-minute offset is a backstop rather than the mechanism. A headless pass fires
`SessionEnd` when it exits, which already kicks a sync; the offset only guarantees staged
candidates reach the remote if that hook ever fails to fire.

| File | Role |
|---|---|
| `scripts/reflect-batch.sh` | The pass. Finds unread transcripts, invokes `/reflect` on them, records what it read |
| `scripts/install-reflect.sh` | Installs the timer — systemd on Linux, launchd on macOS. Idempotent; `--uninstall` removes it |
| `reflect-state.json` | The dictionary of what has been read. Machine state, untracked |
| `hooks/reflect.log` | Output of every pass |

```
reflect-batch.sh --status      what is due, and what has been read
reflect-batch.sh --dry-run     show the batch and the prompt; invoke nothing
reflect-batch.sh --mark-seen   record every current session as read WITHOUT reading it
reflect-batch.sh --limit N     cap sessions per pass (default 8)
```

**The transcripts are the queue.** There is no list of pending work — the pass scans
`projects/*/*.jsonl` and diffs against the state dictionary, so a session that predates the
install, or one whose hook never fired, is still found. A marker file would be a second
source of truth that can drift from the first.

**Keyed by session id, not by a watermark.** Sessions end concurrently and out of order, so a
"last processed" timestamp silently skips any session that ended before the mark but was
written after it. The dictionary also records *how many lines* were read, because a session
resumed after being reflected keeps its id and gains lines — the next pass reads only the
new ones.

**Staleness is content, never mtime.** `git checkout`, `rsync` and restore-from-backup all
move timestamps without changing content, and appends can leave mtime looking untouched. Each
entry stores a hash of the lines already read; if that hash stops matching, the transcript was
rewritten rather than appended, and the pass reports it instead of guessing.

**A session must look parked, not merely paused.** Because the pass runs during working hours
and not only overnight, a transcript is skipped unless it has been untouched for
`QUIET_SECONDS` (3600). A correction read out of a session someone is still in can be
superseded by what they do twenty minutes later, and the pass cannot know that.

**At-least-once, on purpose.** State is recorded only after a pass succeeds, so a crash
re-reads those sessions rather than losing them. That is the safe direction for everything
except the occurrence counter, which increments and gates promotion — so `reflect` is told not
to append an occurrence whose session id and quote it already holds. Until that check lives in
the skill itself rather than in the prompt, treat early passes as proposals to read rather
than counts to trust.

Check on it with `systemctl --user list-timers claude-reflect.timer` and
`tail -f ~/.claude/hooks/reflect.log`.

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
Five stages:

- **Stage 1 — Requirements.** A capability list plus an explicit out-of-scope list, then a
  one-page plan naming the decisions, the build order, and the single risk most likely to
  invalidate everything.
- **Stage 2 — Make it work.** The simplest version, one component at a time, stopping at each
  for review — hardcode freely, stay flat, run it constantly, and never wrap something you
  don't understand in `try`/`except`.
- **Stage 2.5 — Make it readable.** A subtraction-only pass: delete narration comments, dead
  code, and any abstraction with one caller.
- **Stage 3 — Make it scale.** Design, but only after measuring, and only where the
  measurement points.

Ordering rule throughout: build so the cheapest disconfirming evidence comes first.

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

# Version control

## checkpoint-commits

### Description
Commit at each completed checkpoint without being asked, then offer — without blocking — to
keep those commits, squash a chosen set, or fold them into one.

### What it does
Makes the safety net automatic. Work that is not committed is work that can be lost, and
**asking permission first is what makes a safety net useless** — so the commit and the
question about history are separated: the commit happens immediately, the shape of the
history is decided later, at leisure.

### How it works
One commit per large task is the heuristic, and the moments that earn one are the moments
something *became true* — a component passed its gate, a run's result was recorded, a sweep
came back clean. The rule that never bends is that **it reshapes history and never destroys
work**: `reset --soft` is the only reset, `--hard`, `git clean`, `git restore` and `revert`
are all out, and if the only way to honour a request would lose work it refuses and says
which request and why. `rebase -i` is unavailable in this harness, so squashing is
`reset --soft <base>` plus re-commits — the same end state, and it cannot go wrong halfway.
**Commits that exist on a remote are frozen**, since rewriting published history is the one
reshape that genuinely destroys something. The shape question is asked once per natural
pause, not after every commit, because a question asked too often stops being non-blocking.

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

## report

### Description
Write the current work up as a markdown report in a fixed five-section research-paper format —
Title, Abstract, Background, Method, References — with numbered figures and tables.

### What it does
Turns what just happened into a file instead of a scrollback. **It is a sink, not a source**,
and it composes: `/prior-work` then `/report`, `/explain` then `/report`, an afternoon of
debugging then `/report`. The upstream command decides what is true; this one decides where it
goes and what it looks like, and never researches or re-derives to fill a section. Distinct
from its two neighbours: `tldr` prints a 30-second status and writes no file, and `tune-report`
owns hyperparameter sweeps, whose grid and coverage tables are the point.

### How it works
Five numbered sections, always all five, each heading labelled with its slot and carrying its
value — `Title:` states the finding rather than the topic, `Method:` names the approach,
`References:` carries a count that must match the list beneath it, so a list that grew while
the number stayed put is a visible defect. An empty section says `None` **and why**, because an
absent *Background* is ambiguous between "nothing exists" and "nobody looked". Every bulleted
section uses the same two-level shape — a one-line bold title bullet over indented sub-bullets,
split whenever a bullet wraps past two lines — so reading only the bold bullets gives the
argument. Figures and tables are numbered separately, captioned **below** and centered, and
each must be referenced from the text at least once. Frontmatter carries **`source` and
`inputs`**: which command produced the report, and everything it read. No surveyed markdown
format records that — they capture *author* and *date*, which is enough for a human memo and
not enough to tell whether an agent-written explanation still describes the current code. Files
land at `reports/YYYY-MM-DD-HHMM-<slug>.md` and are **never overwritten**; a second report on a
subject is a new dated file carrying `supersedes:`, and the old one gains a superseded-by line.

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
rules), rules that drifted into naming a library version, and skills past a ~500-line cap.
**Caps are forcing functions**: breaching one triggers an audit rather than an append. The
audit adds nothing; a new rule it discovers goes through staging like anything else. It may
never weaken its own constraints.
