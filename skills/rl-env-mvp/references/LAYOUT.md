# Layout

The file tree, what belongs in each module, and the config schema. Read before writing the
first file.

The shape below is not architecture — it is the flattest arrangement that keeps the pure
parts testable without a GPU. Every file is a module a human opens and reads top to bottom.

## Tree

```
config.yaml              every tunable, and the only place a value is decided
config_io.py             load_config + apply_overrides(--set a.b=v)

data/                    the inputs themselves — raw files, caches, fixtures
data_loader.py           task source, prompt builder, train/held-out split
environment.py           prompts -> completions (batched generation, k rollouts)
verifier.py              action + example -> structured Verdict
reward.py                Verdict -> scalar, under a named RewardShape
model.py                 load policy + adapter
eval.py                  held-out task metric, greedy
train.py                 the loop; algorithm selected from config
run_logger.py            per ml_logging — run name, config snapshot, metrics.jsonl

scripts/probe.py         is this configuration trainable? (no training)
scripts/verify_metrics.py  do the metrics mean what their names say — see ml_logging
scripts/sweep.py         runs a declared grid — the tuning session's tool, not this one's
sweeps/*.yaml            grid specs, one per hypothesis

tests/                   unit — one component's behaviour
tests/integration/       seams — real data across a real boundary

PLAN.md                  the six inputs, decisions, build order, the big risk
journal/                 the written record — the only place conclusions live
  experiments.md         run log, the reasoning about it, coverage and the live queue
  prompts.md             every prompt considered, its full text, and what it measured
  rewards.md             every reward shape, its full tier table, and reward vs task metric
  learnings.md           traps, so they cost time once
output/                  everything a run produces; nothing here is hand-edited
  runs/<run_name>/       config.yaml, metrics.jsonl, summary.json, checkpoints/
  configs/<run_name>.yaml  the same snapshot, flat and greppable across all runs
  eval/                  scored held-out results
  sweeps/<sweep_name>/   per-cell logs and the results table
```

**`data/` in, `output/` out.** Nothing written by a run ever lands outside `output/`, which
is what makes the whole directory safe to gitignore, delete and regenerate. If a run writes
somewhere else, that path is a bug — a stray checkpoint beside the source is how a repo
becomes unclonable.

Split unit and integration tests by **what makes them fail**: a unit test goes red when one
component changes, an integration test goes red when an interface between two moves. A red
run then localises the problem before you have read a line.

## What goes in each module

**`journal/`** — The project's written record, kept together because the four files are
read together and cross-reference each other constantly. `PLAN.md` stays at the root: it is
the entry document, not a record.

`journal/prompts.md` exists because the prompt is usually the largest single lever on an RL task and
the least likely thing to be written down. Code holds only the *active* prompt styles;
`journal/prompts.md` holds every style considered — full text verbatim, what behaviour it was
trying to elicit, what it measured, and the verdict. **A rejected prompt keeps its entry
after it is deleted from code**, because "we tried that and it was worse" is exactly the
knowledge a later session cannot reconstruct from a diff.

`journal/rewards.md` exists because the reward shape is a **frozen control** — each shape
lives in its own block, so `experiments.md` cannot compare them without a bridge run, and
the comparison has to live somewhere. It holds every shape's full tier table verbatim, and
for each run under it, **`reward/mean` beside the task metric and the gap between them**.
That pairing is the reward-hacking detector: a gap that widens while the task metric
flattens means the policy is farming partial credit, and neither column shows it alone.

**`data/`** — Input data and anything else that is an *input* rather than logic: raw or
downloaded files, cached generations, hand-written fixtures for the harness gate, a prompt
template that has outgrown a string literal. Nothing here is imported. Keeping it out of
the module lets it be gitignored, regenerated, or swapped for a different corpus without a
code change — and it keeps the repo readable when the corpus is large.

For fully generated tasks the directory may stay empty; create it anyway, because the
hand-written known-good fixtures from L2 belong in it.

**`data_loader.py`** — Build the example, build the prompt, split. One frozen dataclass
carrying everything downstream needs: the inputs, the prompt, and — if it exists — the reference
solution. Carry the reference *in the example*, not in a side table; the harness gate needs
it and a side table will drift.

Prompt styles belong here as a **named dict**, not a single f-string. The prompt is a
difficulty dial and it will be swept.

**`environment.py`** — Prompts to completions. Returns a rollout carrying the **text and
its token count**, because a truncated completion and a failed one are the same string
otherwise, and they call for opposite fixes.

**`verifier.py`** — Pure. Returns a structured verdict with the tiers the reward needs:
did it parse, is it well-formed, is it correct, what did it produce, what went wrong.
Never `eval`. Never a subprocess if a parser will do.

**`reward.py`** — Pure. `compute_reward(completion, example, shape) -> Reward`. The
`Reward` carries the scalar **and** whether it was actually correct, so a policy that
learned the task stays distinguishable from one that learned to look like it.

**`model.py`**, **`eval.py`**, **`train.py`** — thin. `train.py` holds the algorithm branch
and the metric translation table; nothing else.

**`scripts/`** — recipes, not components. Nothing imports them. `probe.py` is on the
critical path — it is gate L4. `sweep.py` is not: it belongs to the tuning that follows, so
leave it unwritten until the first fine-tune has run and there is something to sweep. A recipe that needs
different behaviour composes the modules differently rather than adding a flag to one.

## Config

Every value someone will want to change lives in YAML; nothing computed does. Composition
and derivation happen in the code that reads the config, never in the file.

**What follows is the set of sections and what each is responsible for — not a schema to
copy.** Key names should match whatever trainer you are actually using, because a config
that renames its trainer's own parameters forces a translation layer that will drift. If
you are on TRL, use TRL's names; on verl or a hand-rolled loop, use theirs.

| Section | Responsible for | Notes |
|---|---|---|
| `seed` | the one seed everything derives from | top level, not per-section |
| `data` | where examples come from, how many, the train/held-out split, the **difficulty dial**, the prompt style | name the difficulty knob explicitly — it is what the probe tunes |
| `model` | which policy, its precision, and how it is adapted | adapter-vs-full, quantization and dtype depend on the hardware, so read them from config rather than hard-coding |
| `environment` | rollouts per prompt, sampling params, the generation cap, generation batch size | the cap is a cost setting; see the budget note |
| `reward` | the active shape, and the table of named shapes | shapes named so comparing them is a sweep axis, not a code edit |
| `train` | algorithm choice, learning rate, batch/accumulation, steps, algorithm-specific terms | names follow the trainer |
| `eval` | held-out generation settings | must track the environment's cap, or the comparison is invalid |
| `logging` | per [`ml_logging`](../../ml_logging/SKILL.md) — project, mode, tags, output dirs | |

A sketch of the shape, with placeholders where a real value depends on the task and the
hardware. Fill them from the intake; do not carry them over from another project.

```yaml
seed: 0

data:
  source: <generated | file>
  n_train: <int>
  n_eval: <int>                  # large enough that the noise floor is smaller than the
                                 # effect you need to detect — state both in experiments.md
  difficulty: <the dial>         # name it for what it controls, not "difficulty"
  prompt_style: <one of data_loader.PROMPT_STYLES>

model:
  name: <model id>
  dtype: <precision available on the target hardware>
  device: <read from config; never hard-coded>
  # adapter / quantization block here if used — omit entirely for full fine-tune

environment:
  rollouts_per_prompt: <k>       # must agree with the trainer's own group-size parameter
  temperature: <float>
  top_p: <float>
  max_new_tokens: <near the observed completion length, not comfortably above it>
  batch_size: <int>

reward:
  shape: <the active one>
  shapes:                        # every shape from the intake, named
    <name>: {<tier>: <value>, ..., correct: 1.0}

train:
  algorithm: grpo                # grpo | ppo | rloo — the default; switch deliberately
  learning_rate: <float>         # write 5.0e-5, not 5e-5 — YAML 1.1 loads the latter as a string
  steps: <int>
  # batch / accumulation / algorithm-specific terms, named as your trainer names them.
  # Add a comment stating how many distinct prompts back one gradient step.

eval:
  max_new_tokens: <same as environment.max_new_tokens>
  batch_size: <int>

logging:                         # per ml_logging
  wandb_project: <project>
  wandb_mode: online             # always; offline/disabled are the automatic fallback, not a choice
  tags: [<what the run is>, <what it ran on>]
  progress: auto                 # auto | plain | off — console rate + ETA
  results_dir: output/runs
  configs_dir: output/configs
```

### Budget arithmetic

Do this on paper at intake, before building anything, and again with measured numbers after
the probe. It is what decides whether the project is interactive or stalled.

```
completions_per_step = prompts_per_step x rollouts_per_prompt      # however your trainer spells it

step_time            ~ (completions_per_step / generation_batch) x time_per_batch_at_cap
experiment_time      = step_time x steps  +  eval_time
```

Two consequences that are easy to miss:

- **`time_per_batch_at_cap` tracks the cap, not the mean completion length**, whenever
  generation is batched and the batch returns only once its longest sequence finishes. On
  one measured task, raising the cap from 768 to 2048 cost ~4x while mean length rose 25%.
  Where generation is continuous-batched — a serving engine rather than a `generate()` call
  — this weakens, so measure rather than assume it.
- **`prompts_per_step` is the real batch size** for a group-based algorithm, and it is
  often far smaller than the config suggests. 32 completions at 8 rollouts per prompt is
  **four distinct problems per gradient step**.

If `experiment_time` exceeds the intake budget, fix it here by choosing a smaller model, a
lower cap, or fewer steps — not later by hoping. Say which you chose and why.
