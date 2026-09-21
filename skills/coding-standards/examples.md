# Standards — Examples

A violation and its fix for each rule in `CODING_STANDARDS.md`, in the same order. Consult the entry for a rule before flagging it, so the finding names a concrete shape rather than a feeling. Examples are Python; the rules are language-agnostic.

---

## Blocking

### Errors surface at a boundary

```python
# Violation — the failure is swallowed and the caller gets a wrong answer
def load_weights(path):
    try:
        return torch.load(path)
    except Exception as e:
        logger.error(f"failed: {e}")
        return None          # caller now trains from random init, silently
```

```python
# Fix — propagate; the entry point decides what to do about it
def load_weights(path):
    return torch.load(path)  # FileNotFoundError propagates with the path in it
```

### Errors carry the offending value

```python
# Violation
raise ValueError("invalid config")

# Fix
raise ValueError(f"lr must be > 0, got {lr} (from {config_path})")
```

### Configuration is data, and YAML is the source of truth

```python
# Violation — config as executable code; the running values can't be diffed or read
class Config:
    batch_size = 32
    lr = 3e-4 if USE_ADAM else 1e-3
```

```yaml
# Fix (exploring) — values in YAML
batch_size: 32
lr: 3.0e-4
seed: 1234
```

```python
# Fix (exploring) — read the declared attribute set, no schema yet
cfg = yaml.safe_load(open(path))
batch_size = cfg["batch_size"]
lr = cfg["lr"]
seed = cfg["seed"]
```

```python
# Fix (locked-in) — once the attribute set has stopped moving
class TrainConfig(BaseModel):
    batch_size: int
    lr: float
    seed: int

cfg = TrainConfig(**yaml.safe_load(open(path)))   # typo fails at startup
```

### Randomness, time, and identity are injected

```python
# Violation — unreproducible; the run cannot be repeated to debug it
def make_env():
    return Env(start_state=random.randint(0, 100))
```

```python
# Fix — seed comes from config, flows down explicitly
def make_env(rng: np.random.Generator):
    return Env(start_state=rng.integers(0, 100))

rng = np.random.default_rng(cfg["seed"])
```

### No magic numbers or strings in logic

```python
# Violation
if len(buffer) > 10000:
    flush(buffer)

# Fix
if len(buffer) > cfg["buffer_flush_size"]:
    flush(buffer)
```

### Public signatures are typed

```python
# Violation
def sample(self, batch, replace):

# Fix
def sample(self, batch_size: int, replace: bool = False) -> Batch:
```

### Dead code is deleted

```python
# Violation
# old_reward = compute_reward_v1(state)   # keeping in case we revert
reward = compute_reward_v2(state)

# Fix — delete it; git has it
reward = compute_reward_v2(state)
```

---

## Should-fix

### Names describe the thing, and carry the unit

```python
# Violation
def wait(t): ...          # seconds? ms? ticks?

# Fix
def wait(duration_seconds: float): ...
```

### A function does one thing, at one level of abstraction

```python
# Violation — parses, validates, trains, and writes
def run(path): ...

# Fix
cfg = load_config(path)
model = train(cfg)
save_checkpoint(model, cfg["out_dir"])
```

### Duplicate twice before you abstract

```python
# Violation — two call sites, already abstracted into a parameterised helper
def process(data, mode):
    if mode == "train": ...
    elif mode == "eval": ...

# Fix — leave them separate until a third case or a shared change appears
def process_train(data): ...
def process_eval(data): ...
```

### The public surface is declared; everything else is private

```python
# Violation — a test reaches into internals and breaks on every refactor
from data.loader import _normalise_batch

# Fix — the module declares its surface; tests use it
# data/loader/__init__.py
__all__ = ["DataLoader", "Batch"]
```

### Interfaces declare the contract of what crosses them

```python
# Violation — malformed data is discovered three layers downstream
def step(self, obs): ...
```

```python
# Fix — the contract is stated and checked at the seam
def step(self, obs: np.ndarray) -> StepResult:
    """obs: (batch, obs_dim) float32."""
    assert obs.dtype == np.float32, f"expected float32, got {obs.dtype}"
    assert obs.shape[1] == self.obs_dim, f"expected obs_dim {self.obs_dim}, got {obs.shape[1]}"
```

---

## Composition

### Separate computation from effects

```python
# Violation — the decision can only be tested by writing a file
def maybe_checkpoint(model, metrics, step):
    if metrics["loss"] < self.best:
        torch.save(model, f"ckpt_{step}.pt")
```

```python
# Fix — decide purely, act at the edge
def should_checkpoint(loss: float, best: float) -> bool:
    return loss < best

if should_checkpoint(metrics["loss"], best):
    torch.save(model, path)
```

### Imports go at the top of the file

```python
# Violation — nothing in the header says this module needs torch, and a missing
# install surfaces only once generation is reached, after the data has loaded.
def sample_rollouts(model_name, prompts):
    import torch
    from transformers import AutoModelForCausalLM
    ...

# Fix
import torch
from transformers import AutoModelForCausalLM

def sample_rollouts(model_name: str, prompts: list[str]) -> list[str]:
    ...
```

```python
# The exception, and it says which one it is:
try:                        # optional: the module must import without wandb installed
    import wandb
except ImportError:
    wandb = None
```

### Functions are defined at module level

```python
# Violation — score() is unreachable from a test, and its real inputs are invisible:
# nothing in its signature mentions sandbox or prefix.
def make_reward_fn(sandbox, prefix):
    def reward(completions, tests):
        def score(item):
            return run(item, sandbox["timeout_seconds"], prefix)
        return [score(i) for i in zip(completions, tests)]
    return reward
```

```python
# Fix — both are importable and testable, and each signature names everything it uses.
def score_one(item: tuple[str, str], timeout_seconds: int, prefix: list[str]) -> Reward:
    return run(item, timeout_seconds, prefix)

def reward(completions: list[str], tests: list[str],
           timeout_seconds: int, prefix: list[str]) -> list[float]:
    scorer = partial(score_one, timeout_seconds=timeout_seconds, prefix=prefix)
    return [scorer(i).value for i in zip(completions, tests)]

# The caller binds the fixed arguments where a closure used to capture them.
reward_fn = partial(reward, timeout_seconds=15, prefix=firejail_prefix(...))
```

### Dependencies are injected at construction

```python
# Violation
class Trainer:
    def __init__(self):
        self.loader = DataLoader(DEFAULT_PATH)   # cannot be swapped or faked

# Fix
class Trainer:
    def __init__(self, loader: Loader):
        self.loader = loader
```

### Reuse by composition, not inheritance

```python
# Violation — inheriting to borrow behaviour
class CachedLoader(DataLoader):
    def load(self, i): ...

# Fix — hold and delegate
class CachedLoader:
    def __init__(self, inner: Loader):
        self.inner = inner
    def load(self, i): ...
```

### No mode flags in signatures

```python
# Violation — unreadable at the call site
result = evaluate(model, True)

# Fix
result = evaluate_greedy(model)
```

### Accept the least specific input that works

```python
# Violation — excludes generators, ranges, and anything streamed
def summarise(items: list[float]) -> float:

# Fix
def summarise(items: Iterable[float]) -> float:
```

### Compose what already exists separately; don't split what has never varied

```python
# Violation — three single-use functions where one clear body existed
def _a(x): ...
def _b(y): ...
def _c(z): ...

# Fix — one readable function until a second caller appears
def normalise_batch(batch: Batch) -> Batch: ...
```

---

## State

### Prefer immutability; make ownership explicit when you don't

```python
# Violation — mutates a caller's array with no signal that it does
def normalise(x):
    x -= x.mean()
    return x
```

```python
# Fix (small values) — return a new value
def normalise(x: np.ndarray) -> np.ndarray:
    return x - x.mean()
```

```python
# Fix (large buffers) — mutation is intended; name it, document it, own it
def normalise_in_place(buffer: np.ndarray) -> None:
    """Mutates `buffer`. The ReplayBuffer owns its lifetime; callers borrow it
    for the duration of the call and must not retain a reference."""
    buffer -= buffer.mean()
```

Copying a multi-gigabyte tensor to satisfy a style rule is the wrong trade. The finding is ambiguous ownership — two components each believing they may write — not mutation itself.

---

## Maintainability

### Design patterns name abstractions you already need *(locked-in)*

```python
# Violation while exploring — a factory with one implementation
class OptimizerFactory:
    def create(self, name):
        if name == "adam":
            return Adam()

# Fix — construct it; add the factory when a second optimizer arrives
optimizer = Adam(lr=cfg["lr"])
```

See `patterns.md` for which pattern fits which friction once you're locked in.

### Comments explain why

```python
# Violation — restates the code, and rots silently
# increment the counter
counter += 1

# Fix — states what the reader can't recover
# Env resets are off-by-one against the paper's indexing (see ADR-004).
counter += 1
```

### Long explanation lives in the docstring, not inline

```python
# Violation — a five-line rationale wedged in the middle of the body
def run_vllm(model_name: str, port: int) -> None:
    # We use subprocess.Popen here instead of subprocess.run because Modal's
    # web_server decorator needs this function to return immediately so it can
    # start polling the port; a blocking call would make Modal think startup
    # hung and time out after startup_timeout. vllm serve blocks forever once
    # it starts, so it has to be launched as a detached background process.
    subprocess.Popen(f"vllm serve {model_name} --host 0.0.0.0 --port {port}", shell=True)

# Fix — the rationale moves to the docstring; the body stays uninterrupted
def run_vllm(model_name: str, port: int) -> None:
    """Launches vLLM as a detached background process.

    Must return immediately, not block: Modal's web_server decorator polls
    the port after this function returns, and vllm serve never returns on
    its own.
    """
    subprocess.Popen(f"vllm serve {model_name} --host 0.0.0.0 --port {port}", shell=True)
```

### Docstrings are capped at 4 lines

```python
# Violation — 11 lines of rationale, most of it not load-bearing
def log_weave_evaluation(run_name: str, evaluation_name: str, result) -> None:
    """Replays one Braintrust `EvalResultWithSummary` into Weave as a real `weave.Evaluation`,
    so it shows up in Weave's comparison table and Leaderboard. Call only when `wandb_mode`
    is `"online"` and `weave.init()` has already run (`eval_logger.py`'s own gate) — otherwise
    this is a harmless no-op (weave ops silently skip publishing without an active client, the
    same behavior `model_client.py`'s `call_model()` already relies on).

    `evaluation_name` (`EvalLogger.next_weave_eval_name()`, shaped `<run_id>_weave_<n>`) is
    forced onto `evaluation_name=`, which Weave uses (see its own
    `default_evaluation_display_name`) as this call's display name in the UI — without it,
    Weave picks its own random `eval-<date>-<adjective>-<noun>` name, unrelated to the run_id
    this run's W&B Run and `RunManifest` both use."""

# Fix — the essential why survives; the rest was restating the caller's own gate
def log_weave_evaluation(run_name: str, evaluation_name: str, result) -> None:
    """Replays one Braintrust result into Weave as a real weave.Evaluation. Only called
    when online and weave.init() has run — otherwise a harmless no-op. `evaluation_name`
    (`<run_id>_weave_<n>`) is forced onto `evaluation_name=` so Weave's display name
    matches this run's own id, instead of picking its own unrelated random name."""
```

### A performance change cites its measurement

```
# Violation, in the PR: "made the loader faster"

# Fix: "batch collation moved to workers.
#  8.1s -> 2.3s per epoch, 50k samples, batch 256, 4 workers, RTX 4090."
```

### A new dependency justifies itself in the PR

```
# Fix: "adds `orjson`. Replaces hand-rolled encoder in serialise.py (-60 lines).
#  stdlib json is 4x slower on our trace payloads. No transitive deps."
```
