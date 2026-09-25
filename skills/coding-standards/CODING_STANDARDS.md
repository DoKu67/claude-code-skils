# Coding Standards

Code has two audiences: the machine that runs it and the human who debugs it at 2am. These rules serve the second one. Working code that can't be read or traced is unfinished.

Worked examples and fixes for every rule: [`examples.md`](examples.md), beside this file.

These standards are global — they live beside this file in `skills/coding-standards/` and apply to every project, without exception. There is no per-repo override file. A repo that seems to need one is either revealing a rule that should change globally, or a convention that belongs in that repo's `CLAUDE.md` or `AGENTS.md` as context rather than as a competing standard.

## Stage

Rules divide by **stage**, because an abstraction chosen before the code works is a guess that everything downstream then has to honour.

- **Exploring** — the shape of the solution is still moving. Get it correct and readable. Rules marked *locked-in* are silent here; raising them is itself a finding.
- **Locked-in** — the code works, the interfaces have stopped moving, and the cost is now maintenance. Abstractions earn their keep, and *locked-in* rules bind.

Nothing transitions on a schedule. A module is locked-in when its interface has survived two changes without moving. Say which stage a module is in when it isn't obvious; when in doubt, it's exploring.

## Tiers

**Blocking** — don't merge. **Should-fix** — merge only with a stated reason. **Nit** — mention once, never block.

Rules are judgement calls, not gates. Where tooling already enforces a rule, tooling wins and review stays silent.

---

## Blocking

**Errors surface at a boundary.**
Catch an error only where you can act on it — a request handler, a CLI entry point, a job runner. Everywhere else it propagates. A catch that logs and continues has converted a loud failure into a silent wrong answer, and the wrong answer is discovered much later and much more expensively.
*Doesn't apply when:* the catch genuinely recovers — retry with backoff, a documented fallback. That belongs wherever the recovery lives; note it in a comment.

**Errors carry the offending value.**
`ValidationError("expected positive, got -3 for retry_limit")`, not `ValidationError("bad input")`. The message is the debugging session — an error without its value sends the reader back to reproduce something the program already knew.

**Configuration is data, and YAML is the source of truth.**
Every tunable value lives in YAML. Code reads a declared set of attributes out of it; config files hold values, never computed logic. Configuration expressed as executable code makes the running configuration unknowable without executing it, and it makes two runs impossible to diff.
*Doesn't apply when:* composition and derivation are needed — those happen in the code that reads the config, never in the file.
*Locked-in:* once the attribute set has stopped moving, validate it through a schema (Pydantic or equivalent) at load, so a typo fails at startup rather than forty minutes into a run. While exploring, plain extraction of the named attributes is correct and a schema is premature.

**Randomness, time, and identity are injected — and the seed lives in config.**
Anything stochastic takes its seed as a parameter, sourced from the YAML; clocks, UUIDs, and connections are passed in rather than reached for. One rule doing three jobs: runs become reproducible, tests become deterministic without patching, and the dependency graph becomes visible. A function that reads a global seed or calls `now()` internally cannot be re-run to the same result, which means a bug in it cannot be pinned down.

**No magic numbers or strings in logic.**
A literal in a branch, a threshold, a retry count, a URL — name it as a constant or hoist it to config. An unnamed literal hides both its meaning and the fact that it's tunable.
*Doesn't apply when:* the meaning is exhausted by context — `range(2)` for a pair, `[]` for empty.

**Public signatures are typed.**
Every parameter and return on anything callable from outside its module. Internal helpers may infer. Types on the public surface are the contract; types on internals are often churn while exploring.

**Secrets never appear in code, logs, error messages, or test fixtures.**

**Dead code is deleted.**
Commented-out blocks and `if False:` branches are weight every future reader must evaluate and every search must wade through. Version control remembers it; you don't have to.

---

## Should-fix

**Names describe the thing, and carry the unit.**
`timeout_seconds`, not `timeout`. `retry_limit`, not `n`. A name without its unit is a bug waiting for someone to pass milliseconds.
*Doesn't apply when:* the letter *is* the domain convention — `i` in a tight index loop, `x`/`y` for coordinates, notation matching a cited formula.

**A function does one thing, at one level of abstraction.**
The tell is the honest name: if it needs "and", split it. Mixed levels of abstraction in one body force the reader to change altitude mid-sentence.

**Duplicate twice before you abstract.**
Three occurrences, or two that have already changed together, earn the abstraction. A wrong abstraction is paid for by every caller, forever; duplication is paid for once by whoever consolidates it.
*Doesn't apply when:* the call sites look alike but change for different reasons. Those are not duplicates and merging them couples two things that should move independently.

### Interfaces

**The public surface is declared; everything else is private.**
A module names what the rest of the codebase may reach — that set is the interface. Everything else is internal and prefixed or scoped as private, free to change without notice. File and directory structure mirrors the public surface, so the boundary is visible from the tree rather than inferred from imports.
This is what makes testing tractable: tests exercise the public surface and stay valid across refactors, because internals were never promised to anyone. A seam you can't name is a seam you can't test.

**Interfaces declare the contract of what crosses them.**
Not just types — the properties a caller can rely on. For array and tensor boundaries that means declaring shape and dtype and asserting them at the seam; elsewhere it means declaring ordering, nullability, or units. A boundary that accepts anything provides no information about where a malformed value entered, and debugging becomes bisection across the whole pipeline.

### Composition

Units are built to combine. A codebase composes when a new requirement is met by arranging existing pieces rather than editing them. Composition is the property to protect above the others in this section — it's what keeps the code changeable once it's locked in.

**Separate computation from effects.**
Decisions, transformations, and calculations are pure functions returning values; reading and writing the outside world happens in a thin layer that calls them. A function that computes *and* writes can only be exercised by exercising the write. Most code that resists composing has an effect buried in the middle of a calculation.

**Functions are defined at module level.**
A function defined inside another cannot be imported, tested, or called from anywhere else, and it hides what it actually depends on — a helper that looks like it takes two parameters may be reading five more names from the enclosing scope, and nothing in its signature says so. Define it at module level and pass what it needs; `functools.partial` binds the fixed arguments wherever a closure was reaching for them.
*Doesn't apply when:* a single-expression `lambda` handed straight to a `sort`, `map`, or `filter`, where naming it costs more than it explains.
This rule is **not gated on stage.** Exploring is where nesting accumulates fastest — the enclosing scope is right there and closing over it is the path of least resistance — and it is far cheaper to not write than to unpick once the outer function has callers.

**Imports go at the top of the file.**
All of them, at module level, before any other statement. An import buried inside a function hides a dependency from the reader of the file's header, defers its failure to whenever that function first runs — often an hour into a job that had already done real work — and disguises what the module actually costs to load. The header is the honest dependency list, and it is only honest if it is complete.
*Doesn't apply when:* breaking a genuine circular import, or guarding a truly optional dependency whose absence must not stop the module from loading. Both are rare and both earn a comment naming which one it is. "It made the test suite start faster" is not one of them — that cost is real but it is paid once per process, and hiding it does not remove it.

**Dependencies are injected at construction.**
A component receives its collaborators; it does not construct or locate them. This is what makes the interfaces above substitutable, and what lets the same component be arranged differently in a different context.

**Reuse by composition, not inheritance.**
Inheritance couples a subclass to its parent's internals and to every future change in them. Hold the collaborator and delegate.
*Doesn't apply when:* declaring *is-a* within a stable, deliberately designed hierarchy.

**No mode flags in signatures.**
A boolean or enum that selects between behaviours is two functions wearing one name — the body forks on it, callers pass a literal nobody can read at the call site, and neither branch composes.
*Doesn't apply when:* the flag tunes a single behaviour rather than switching it (`strict=True`, `timeout_seconds=30`).

**Accept the least specific input that works.**
Take an iterable rather than a list, a stream rather than a path, a value rather than a config object you read one field from. Every narrowing of a parameter type excludes a caller from composing with it.

**Compose what already exists separately; don't split what has never varied.**
Decomposing a working unit into pieces nothing else calls buys nothing and costs a layer of indirection. Where this and the duplication rule disagree, they point at the same tiebreaker: wait for the second real case.

### State

**Prefer immutability; make ownership explicit when you don't.**
Default to returning new values rather than modifying arguments — shared mutable state is the hardest class of bug to reproduce.
*Doesn't apply when:* copying is the wrong trade. Large buffers, tensors, and arrays are passed by reference and mutated in place on purpose; forcing a copy to satisfy a style rule is a real cost paid for an imagined benefit. When you mutate what you were handed, three things are required: the name says so (`normalise_in_place`), the docstring states it, and exactly one component owns the buffer's lifetime. Ambiguous ownership — two callers both believing they may mutate — is the finding, not mutation itself.

### Maintainability

**Design patterns name abstractions you already need.** *(locked-in)*
Once the code works and the interface has settled, reach for the shared word for a shape that has already emerged — it makes interchangeable components cheap to swap. Candidate patterns and when each fits: [`patterns.md`](patterns.md).
*Doesn't apply when:* still exploring. Introducing a pattern to anticipate a need is Speculative Generality — flag it as such, and prefer the composition rules above, which get you most of the interchangeability without committing to a structure.

**Comments explain why.**
Rationale, tradeoffs considered, the reason the obvious approach fails here. A comment explaining *what* the code does is a naming failure — rename, then delete the comment. What-comments also rot silently, because nothing breaks when they stop being true.

**Long explanation lives in the docstring, not inline.**
A rationale that runs more than two lines belongs in the function's docstring, not as a comment dropped in the middle of the body. The docstring is the first thing a reader — and a diff — sees; a multi-line aside buried between statements interrupts the one thing a reader is doing at that point, which is tracing control flow, and it outweighs its own importance by sitting there. Keep inline comments to a line or two, pointing at the one statement they annotate.
*Doesn't apply when:* the rationale is tied to one specific statement buried deep in the body — a workaround for a bug in a particular call, three branches in — where hoisting it to the top would orphan it from the code it explains. That's the exception, reserved for real edge cases, not the default home for long comments.

**Docstrings are capped at 4 lines.**
Beyond 4 lines, a docstring is ranting, not documenting — cut to the essential why, and move real detail to a design doc/report the docstring can point at.
*Doesn't apply when:* a public API's full parameter/return contract genuinely needs the space — rare, and still trimmed of anything not load-bearing.

**A performance change cites its measurement.**
Before/after numbers and the workload they came from. Optimization without a measurement is a guess that also costs readability. Correctness first, then measure, then optimize what the measurement pointed at.

**A new dependency justifies itself in the PR.**
Name what it replaces, why hand-rolling loses, and what it drags in transitively. A dependency is a permanent maintenance obligation acquired in a moment.

**Logs are structured and traceable.**
Emit at boundaries, not inside hot loops, and carry the identifier that lets you follow one request or run end to end.
*This rule is a placeholder.* Logging standards are being developed as a separate skill; until then, review flags only missing traceability and secrets in log output, not level choice or message content.

---

## Nit

**Formatting, import order, and quote style belong to the formatter.** Never raised in review. If no formatter is configured, that's one issue to file, not a comment per line.

**Prefer early returns to nesting.** Past three levels of indentation inside a function, invert the conditions and return early.

**Keep the happy path at the lowest indentation level.** Guard clauses first, then the work.
