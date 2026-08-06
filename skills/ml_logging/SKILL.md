---
name: ml_logging
description: Standardize experiment logging for machine learning runs — run naming, the W&B metric vocabulary, config capture, reproducibility fields, and console progress reporting. Use whenever writing or modifying a training, fine-tuning, evaluation, or RL script; whenever wiring up wandb, a HuggingFace Trainer, or a TRL trainer; whenever the user wants a progress bar, a step rate, or an ETA on a running job; and whenever the user asks why two runs can't be compared or where a run's hyperparameters went.
---

# ml_logging

Every ML run in every repo produces the same shape of record, so that runs from
different projects, months apart, land on the same panels and can be compared
without archaeology.

This skill ships **no code**. It is a contract, applied by writing the logger
that fits the project at hand. The metric vocabulary lives in
[`METRIC_SPEC.md`](METRIC_SPEC.md) beside this file — read it before naming a
single metric.

The logger is written into the project that needs it and stays there. Never
import one across repos; a project's logger is its own file, and two projects
diverging is the expected outcome, not a defect.

## The three rules

**One name, everywhere.** A run gets exactly one identifier, and it is the W&B
run name, the results directory name, and the checkpoint prefix. Anything that
requires a lookup table to connect a run to its outputs has already failed.

That includes the **written record**. Every entry in every `journal/` file — a note, a
learning, a prompt or reward comparison — names the run or runs it came from, beside its
timestamp to the minute. The name is what lets a finding be re-checked when the run behind
it turns out to be broken, and what makes "what did this run teach us" answerable by
grepping one string across the whole journal. An entry without it is folklore the moment
the session ends. Where a finding came from reasoning or a script rather than a run, say
that instead — `from scripts/probe.py`, `from arithmetic, not measured` — so a reader can
tell which claims were tested.

**Local first, W&B second.** Metrics are written to disk as they are produced.
W&B is a mirror. A logging failure never takes down a training run — every W&B
call is wrapped, `online` degrades to `offline` on an init error, and the run
continues.

**`wandb_mode` is `online`.** Always, in every config. `offline` and `disabled` exist as
the automatic fallback above, not as settings to choose — a config that starts at `offline`
means the run never reaches the dashboard and the loss is noticed hours later, if at all.
A genuinely unavailable network is already handled: `online` degrades on its own, and
`wandb sync <run_dir>` backfills the full history afterwards.

**Declare metrics up front.** A task pack's metrics are all declared at init and
logged as `nan` when unavailable. A missing metric must show as a gap in a panel,
never as a metric that silently does not exist.

**And verify the declaration held.** A project ships `scripts/verify_metrics.py`, run after
every training run, asserting three things against the run's own `metrics.jsonl`: every
declared metric carries numeric values, the x-axis exists and advances, and no two
differently-named series are bit-identical.

Because the declaration above is a promise nobody checks. On one project three metrics
reached a log under a name implying something they were not measuring — a trainer emitting
`grad_norm` where the vocabulary declared `train/grad_norm`, an x-axis metric that reached
disk but never the dashboard, and a metric whose name said post-filter while it scored the
pre-filter batch. **Every one was found by a human reading raw values**, none by the rule
above, because each needs *two things compared* rather than one thing read. The third check
is the only mechanical handle on a name that lies.

*Falsified if:* the checks fire mostly on benign aliases, so the output gets ignored — then
the allow-lists are doing the work and the check is theatre.

## Run name

```
MM_DD_HH_MM_SS_{petname}[_{model_slug}][_{task}]
```

```
08_02_15_42_33_witty-otter_qwen3-4b_grpo
08_02_16_11_05_brave-mantis_qwen3-4b_grpo
08_03_09_12_40_calm-heron_llama3-8b_sft
```

Timestamp first and in descending unit order, so lexicographic sort — W&B's run
table, `ls results/runs/` — is chronological order. Year is deliberately
omitted; runs are pruned long before the wraparound matters. The petname
(`petname.generate(words=2, separator='-')`) is what a human says out loud.
`model_slug` and `task` are appended when the project has a meaningful notion of
either; they are the only optional parts.

**Tags never go in the name.** They are declared in the config file and read
from there into `wandb.init(tags=...)` — see below. A tag baked into a name
string is neither filterable nor editable after the run finishes; a tag in the
config is both, and is versioned alongside the hyperparameters it describes.

Sanitize before use: lowercase, non-alphanumerics to `-`, so the name is safe as
a directory, a filename, and a W&B name simultaneously.

## Run directory

The directory *is* the run name. This is what makes the config-to-run link
structural rather than conventional.

```
results/runs/08_02_15_42_33_witty-otter_qwen3-4b_grpo/
    config.yaml       # resolved config that produced this run
    metrics.jsonl     # one JSON object per logged step
    summary.json      # final scalars, written on exit
    checkpoints/
configs/
    08_02_15_42_33_witty-otter_qwen3-4b_grpo.yaml   # same file, findable by run name
journal/
    experiments.md    # one entry per run, linking its configs/ file
```

**`config.yaml` is the resolved config, not the file the user passed.** It is
written after CLI overrides, environment variables, and defaults are all
applied — the thing that actually ran. Preserve the input format: a project
configured by JSON writes `config.json`. It goes to four places:

1. The run directory, as above.
2. `wandb.config`, flattened — this is what powers W&B's parallel-coordinates
   and group-by-hyperparameter views, and a nested dict does not.
3. A W&B artifact, so the exact file is downloadable from the run page later.
4. `configs/{run_name}.{ext}` at the repo root — a second copy under the run's
   own name, outside the results tree.

Write it at init, before the first training step, so a run that crashes in step
zero still explains what it was trying to do.

The fourth copy is what makes experiments comparable. A config buried in
`results/runs/<name>/` is findable only once you already know which run you
want; a flat `configs/` directory makes the whole history greppable and
diffable. `diff configs/A.yaml configs/B.yaml` answers "what was actually
different between these two runs" in one command, rather than by reading a
changelog and trusting it to be complete.

## Every experiment gets a row in `journal/experiments.md`

A run that produced a number and was not written down did not happen — it gets
re-run in three weeks by someone who no longer remembers the result. Each entry
carries the run name, a link to its `configs/` file, the headline metric, and a
one-line **read** of what it means.

Order by what was learned, not by wall clock. Record failures with the same
weight as successes: a run establishing "this approach does not work, and here
is the metric that proves it" is worth more than one that nudged a number,
because it closes a door permanently rather than opening one slightly.

Name the headline metric at the top of the file, and say explicitly which
metrics are **not** comparable across runs. Anything measured on a shifting
subset — training reward over sampled batches, a loss on whatever data the
epoch happened to draw — invites precisely the comparison it cannot support,
and a table full of such numbers reads as evidence when it is noise.

### Every config file carries a `tags` entry

Config files written for real runs — not just the logger that reads them —
include a top-level logging block. When authoring or scaffolding a training
config, add it; when a project's config schema lacks it, extend the schema.

```yaml
logging:
  wandb_project: my-project
  wandb_entity: null          # null → default entity
  wandb_mode: online          # always; offline/disabled are the fallback, not a choice
  tags: [ablation, kl-sweep, 8xh100]
  group: grpo-kl-sweep        # null → ungrouped
  job_type: train             # train | eval | sweep | debug
  progress: auto              # auto | plain | off — console progress; see below
```

`tags` is a flat list of short slugs, and it is the only place tags are set. The
logger reads this block and passes it straight to `wandb.init(tags=..., group=...,
job_type=...)`. Because it lives in the config, the snapshot in the run
directory records which tags a run carried at the time it ran, even if they are
edited in the W&B UI afterwards.

Keep tags to a controlled vocabulary the project reuses — what the run *is*
(`ablation`, `baseline`, `sweep`, `debug`, `smoke`) and what it ran on
(`8xh100`, `1xa100`). Anything with a value — a learning rate, a KL coefficient —
is a hyperparameter and belongs in the config proper, where it is filterable as
a number rather than as a string.

## Hyperparameter grids

A sweep is **a set of ordinary runs**, not a special kind of run. Every cell gets
its own run name, run directory, and config snapshot exactly as above, and is
reproducible on its own without the sweep that launched it. The grid runner
decides *which* runs happen and collects what they produced; it holds no
training logic of its own. If a cell cannot be re-run from its own snapshot, the
sweep has become a second training path and will drift from the first.

**One override mechanism.** A single repeatable flag setting any config key by
dotted path — `--set train.learning_rate=5e-5` — and no per-hyperparameter flags
beside it. Two ways to vary a run means two things to keep in sync, and the sweep
will use the one the human doesn't read.

**An override naming a key that does not exist must raise.** Creating it silently
turns a typo'd axis into a full grid of identical runs, reported as a comparison.
That failure looks exactly like a finding, which is what makes it expensive.

**Watch the value's type.** `yaml.safe_load("5e-5")` returns the *string*
`"5e-5"` — YAML 1.1's float resolver requires a decimal point and a signed
exponent. A learning-rate axis written the natural way hands a string to the
optimizer with nothing type-checking it on the way in. Parse overrides through
YAML, then fall back to `int()`/`float()` when YAML hands back a string.

**The grid is declared as data**, in a spec file versioned beside the code, not
as a shell loop in someone's history:

```yaml
name: lr_batch
axes:
  train.learning_rate: [2.0e-5, 1.0e-4]
  train.gradient_accumulation_steps: [8, 16]
fixed:
  train.max_steps: 120
```

Say in a comment what hypothesis the grid tests and what result would falsify it.
A grid with no stated hypothesis produces a table nobody can act on.

**Each cell is scored against its own config snapshot,** never against the
current working config. A cell that varied the prompt template, the tokenizer, or
the eval set and is then scored under a different one produces a number that
belongs to no run. Pass the run directory's snapshot to the eval explicitly.

**The results table is ranked by the headline metric** and carries the axis
values, the run name, the wall time, and the metrics that explain the ranking.
Name the columns that are **not** comparable across rows — anything measured
under a reward shape, prompt, or eval set that the grid itself varied. A sweep is
the easiest place in a project to line up numbers that cannot legitimately be
compared, because the table format implies they can.

**A cell that crashed is recorded as crashed.** Dropping it leaves a grid that
reads as complete, and the missing cell is usually the informative one — it is
where the configuration became unstable. The same applies to a grid cut short:
log what was not run.

## Metrics

Read [`METRIC_SPEC.md`](METRIC_SPEC.md) for the vocabulary. Two rules that
govern its use:

**Slash-separated namespaces, never underscores.** `train/loss`, not
`train_loss`. W&B groups `train/*` and `val/*` into their own panel sections;
flat names become orphans in one undifferentiated list. This also matches what
HF and TRL already emit, so a hand-rolled loop and a `Trainer` run land on the
same panels.

**One x-axis, many clocks.** Call
`wandb.define_metric("*", step_metric="progress/global_step")` at init, and log
every other clock — `progress/epoch`, `progress/tokens_seen`,
`progress/env_steps`, `progress/episodes` — as ordinary fields. RL in particular
has three clocks that advance at different rates; logging rollout metrics
against the gradient step silently misaligns the curves, and this makes it
re-plottable after the fact instead.

## Wiring

**When you own the loop**, write a run-logger class into the project. Its
constructor takes the resolved config and, in this order: builds the run name,
creates `results/runs/{name}/`, writes the config snapshot, opens
`metrics.jsonl` for append, then inits W&B. W&B goes last so a config snapshot
exists even if init hangs or fails.

Four methods, and no more:

| method | does |
|---|---|
| `log_metrics(step, metrics: dict)` | append one JSON line to `metrics.jsonl`, flush, then mirror to W&B inside a `try` |
| `set_summary(**kw)` | update the in-memory summary dict and W&B's run summary |
| `log_artifact_path(path, name)` | record a produced file in the summary under `artifacts` |
| `finish()` | close the metrics file, write `summary.json`, close W&B; returns the summary path |

Implement `__enter__`/`__exit__` so `finish()` runs on the exception path
without the caller remembering to. `__exit__` is also where `run/status` gets
set from the exception type — see below.

The W&B init is best-effort and its failure mode is specified: `disabled` skips
it entirely; `online` that raises falls back to a second attempt in `offline`
mode so the data is still captured; a second failure leaves the logger
W&B-less and training proceeds. Every subsequent W&B call sits behind a bare
`except` that swallows and continues. The local files are the source of truth
and must never depend on the network.

**When you do not own the loop** — HF `Trainer`, TRL `SFTTrainer`/`GRPOTrainer`,
`rl_games`, `rsl_rl` — do not fight it. Call `wandb.init()` yourself *before* the
trainer starts, with the name, config, tags, and group set per this skill; the
trainer then attaches to the existing run instead of creating its own. Set
`run_name` on `TrainingArguments` to the same name. Then map the trainer's
emitted names onto the vocabulary — `METRIC_SPEC.md` has the translation table.

## Progress display

A run longer than a few minutes gets one line on the terminal answering *how fast* and
*how much longer*. The bar is a **view of numbers already going to `metrics.jsonl`** —
never a second source of them, and never something a metric is read back out of. Its rate
is `train/step_time_s`; no ETA metric is logged, because it is derivable and a logged ETA
is a prediction that ages badly on a dashboard.

It is driven from `log_metrics`, not a fifth method on the logger — the same call that
appends the line advances the bar, so a step that reached disk and a step the user saw
cannot disagree.

**One bar, and its total is the run's total optimizer steps.** A bar totalling the epoch
or `len(dataloader)` reports the ETA for a fraction of the run, and that number is the one
the user actually reads. Where the total is genuinely unknown — a streaming dataset, RL
run to a reward threshold — run it untotalled, showing rate and elapsed and no ETA, rather
than showing an ETA against a guess.

**The postfix carries at most three numbers**: the headline metric, the learning rate, and
throughput. Bar plus postfix must fit one terminal width — a wrapping bar re-renders as
accumulating garbage, which is worse than no bar.

**Nothing else writes to the stream.** Prints and log records inside the loop go through
the bar's write method, or the bar is shredded every line and the scrollback is unusable.
Inner bars — eval, generation — erase themselves on completion (`leave=False`); nested
bars that persist turn a long run into thousands of stale lines.

**Bar to stderr, so redirecting stdout leaves it visible and `> log.txt` stays clean.**

**Interactive and non-interactive are different modes, and the stream decides which** —
`sys.stderr.isatty()`, not a config default. Under `nohup`, Slurm, or CI, a bar emits a
fresh line per update and produces a multi-megabyte log; there, print one progress line
every N steps carrying the same fields (step/total, percent, rate, elapsed, ETA). The
config's `logging.progress` only overrides that decision — `plain` forces the periodic
line, `off` silences it — and defaults to `auto`, which makes it from the stream.

**The bar closes on every exit path**, in the same `__exit__` that calls `finish()`. An
unclosed bar leaves the cursor hidden and the terminal mangled after a Ctrl-C, which is
how a clean interrupt gets misread as a crash.

**When you do not own the loop, use the trainer's own bar.** HF `Trainer` and TRL ship one
(`disable_tqdm`); a second bar beside it produces two ETAs that disagree. Add what it
lacks through the callback's postfix instead.

**Read the ETA against the preflight projection.** Once the rate has stabilized — past
warmup and the first eval — a live ETA that disagrees materially with the wall-clock
projection from [`tune-preflight`](../tune-preflight/SKILL.md) means one of them is wrong,
and it is usually the projection's step-time estimate. That is a reason to re-check the
budget mid-run rather than at the end of it.

## Exit status

Set `run/status` in a `finally` block: `completed`, `crashed`, `oom`, or
`interrupted`. Without it a crashed run and a finished run are indistinguishable
in the W&B table, which is how a broken sweep gets read as a real result.
`finish()` writes `summary.json` and closes W&B on every path, including the
exception path.

**Everything in `summary.json` reaches W&B's run summary as well.** `finish()` pushes the
whole summary dict up *before* closing, not only to disk. `run/status` is set after the last
`set_summary` call, so a logger that writes locally and then closes W&B leaves every run on
the dashboard looking identical whether it completed, crashed or OOM'd — the exact failure
this section exists to prevent, reintroduced one layer down.

That includes metrics computed in a **separate process**. A held-out eval that runs after
training attaches to the run — `wandb.init(id=..., resume="allow")`, with the id recorded in
`summary.json` at init — and writes its result into that run's summary. Otherwise the
dashboard carries the training proxy and not the headline metric, and every ranking has to
be read out of local files whose path only one person knows.

Out of scope for this skill: resume and checkpoint retention policy. Those
are project decisions.

## Done when

The run name matches the template and is used as W&B name, directory, and
checkpoint prefix; the resolved config is on disk under that name, in
`configs/{run_name}.{ext}`, and in `wandb.config`; the run has an entry in
`journal/experiments.md` naming its config and its headline metric; every metric name
comes from `METRIC_SPEC.md` with `/` separators; the core pack plus the task's
pack are all declared; `run/status` is set on every exit path; and killing W&B
auth mid-run leaves training unaffected with metrics still landing in
`metrics.jsonl`.

Progress: the run shows rate and remaining time against the **whole** run's step total on a
terminal, degrades to a periodic line when stderr is not one, and a Ctrl-C leaves the
terminal usable.
