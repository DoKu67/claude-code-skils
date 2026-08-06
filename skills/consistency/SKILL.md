---
name: consistency
description: Sweep for everything a change should have touched and did not — stale references, docs describing the old behaviour, tests and config still on the old name, comments explaining a rationale that no longer applies. Use after any edit that ripples across files: a rename, a signature or default change, swapping the method or library used for something, a documentation update, or any change touching more than one file. Also use when a *result* rather than an edit invalidates a written claim — a run that falsifies a documented assumption, a measurement that contradicts a quoted number, a plan step that closed — because those leave no diff to sweep from. Run it before reporting a multi-file change as done.
---

# consistency

A multi-file change is not done when the edits are made. It is done when nothing left
behind still describes the old world.

The failure is always the same shape: the code is updated and something that *refers* to it
is not — a test name, a docstring, a config key, a log message, a comment explaining a
rationale that no longer applies. Each survivor is a small lie in the codebase, and the
expensive ones are the confident ones: a README example that no longer runs costs more than
a compile error, because nothing fails.

---

## Work from the diff, never from memory

**Enumerate what changed by reading `git diff`, not by recalling what you edited.**

This is the rule the whole skill rests on. In a long change, files edited early fall out of
context while later ones are still being written — so a sweep built from memory checks the
files you happen to still remember, which is exactly the set least likely to have been
missed. The diff does not forget.

```
git status --short
git diff --stat
git diff                    # or `git diff HEAD~1` if already committed
```

If there is no VCS, work from a file listing and timestamps. The point is an external
record of what moved, not a recollection of it.

### When a result is the change, there is no diff

The diff rule has one blind spot, and it is the one that produces the most confident lies: **a
run can invalidate a written claim without touching a single line.** Nothing edited the sentence
quoting the old baseline; a measurement simply made it false. `git diff` is empty, so a
diff-driven sweep never starts, and the stale claim survives indefinitely because it looks
untouched.

So there is a second entry point. Sweep whenever any of these happens, regardless of the diff:

| Trigger | What to search for |
|---|---|
| A falsifier fired, or a step closed | every document asserting that step is pending, or "the next thing", or written in future tense |
| A measurement contradicts a quoted number | that number, as a literal string, everywhere |
| An assumption was disproved | prose that argues *from* the assumption, which will not contain the number |
| A plan was superseded | references to it as current, and its own status line |
| A run revealed a data or environment fact | the auto-loaded context file, which a fresh session believes without checking |

**Grep for the number.** A stale figure is the cheapest survivor to find and the most damaging
to leave: quote it as a literal and check every hit, including the ones inside prose. Then do
the semantic pass for the sentences that *argue* from the old value without naming it — those
are invisible to grep and are where the confident errors live.

The two most valuable targets are the ones nobody edits on purpose: **the plan document**, whose
status line and open questions go stale on every result, and **the auto-loaded context file**,
where a stale claim is read at the start of every future session and acted on. See
[`plan-doc`](../plan-doc/SKILL.md) and [`project-brief`](../project-brief/SKILL.md) for what each
is supposed to assert.

---

## Before editing: the ripple list

Written **before** the change, because afterwards you will enumerate what you touched rather
than what exists.

One line: *what identifier, behaviour or claim is changing, and what classes of artifact
could refer to it?* Then the sweep checks that list rather than your recall.

| Artifact class | Typically missed because |
|---|---|
| **Callers** | Dynamic dispatch, reflection, `getattr`, plugin registries — invisible to a symbol search |
| **Tests** | The test *name* encodes the old behaviour even after the assertion is updated |
| **Docstrings and comments** | They paraphrase rather than quote, so they do not match a grep |
| **README and docs** | Worked examples silently stop working; nothing fails |
| **Config, fixtures, schemas** | Reference things as **quoted strings**, not identifiers |
| **Log and error messages** | Contain the old name in prose, and are read by humans under stress |
| **CLI flags, env vars, API routes** | Public surface; a rename here is a breaking change, not a cleanup |
| **CHANGELOG, migration notes, ADRs** | Describe intent that the change may have just invalidated |
| **Type stubs, generated code, lockfiles** | Regenerated rather than edited, so they are simply forgotten |

---

## The three sweeps

### 1. Literal — the old token is gone

```
rg -i 'old_name' --hidden -g '!.git'
```

Case-insensitive and unanchored, so it catches `OldName`, `OLD_NAME`, `old-name` and the
possessive. **Expect zero hits.** Every remaining hit is either a miss or a deliberate
survivor, and a deliberate survivor gets said out loud — a legacy alias kept for
compatibility is a decision, not an oversight.

Search the **quoted** form too. Config keys, fixture values and serialised data hold the old
name as a string, where no symbol-aware tool will find it.

### 2. Semantic — the old *idea* is gone

The sweep nobody automates, and where the expensive survivors live. Grep cannot find a
sentence that describes the old behaviour without naming it.

Search for the **concept**, not the token: the verb the docs used, the rationale a comment
gave, the number a doc quoted. If the change swapped a method, search for the old method's
*justification* — "we use X because it's faster" outlives the removal of X and then argues
for undoing the change.

| Change kind | What the semantic sweep looks for |
|---|---|
| Rename | Prose paraphrases, test names, log wording |
| Signature or default change | Docs quoting the old default; examples passing the old arg |
| Swapped method or library | Comments justifying the old choice; benchmarks; dependency lists; install docs |
| Behaviour change | Docs stating the old guarantee — complexity, ordering, idempotency, limits |
| Documentation update | **The inverse:** does the code actually do what the doc now claims? |

### 3. Inverse — what points *at* what changed

For each changed file, ask what refers to it: imports, docs naming the file, CI paths,
build config, entry points. [`call-tree`](../call-tree/SKILL.md) answers the code half of
this quickly. A file that was moved or renamed is where this sweep earns itself.

---

## Then verify

A sweep proves nothing on its own. Run what actually exercises the change — the tests, the
import, the CLI command, the doc example pasted verbatim into a shell. **A documentation
example is only correct if it was run**, and it is the single most common thing to be
confidently wrong.

---

## Report

```markdown
## Consistency sweep — rename `get_user_by_id` → `fetch_user`

**Changed:** 6 files (from `git diff --stat`)

| sweep | checked | found | action |
|---|---|---|---|
| literal | `rg -i get_user_by_id` | 3 hits | 2 fixed; 1 kept — deprecated alias in `compat.py`, deliberate |
| literal (quoted) | fixtures, config | 1 hit | `tests/data/roles.yaml` fixed |
| semantic | "look up a user by id" in docs | 2 hits | README example and a docstring rewritten |
| inverse | importers of `db/users.py` | 4 files | all already updated |
| verify | `pytest tests/` | 41 passed | — |

**Left deliberately:** `compat.get_user_by_id` alias, removal scheduled — noted in CHANGELOG.
**Not checked:** generated client in `sdk/` — regenerated from the spec, out of this change's scope.
```

Two lines carry the weight: **what was left deliberately**, so a survivor is not mistaken
for a miss, and **what was not checked**, so the sweep is not read as more complete than it
was.

---

## When to stop and ask

The sweep is also a scope alarm. Escalate per [`escalate`](../escalate/SKILL.md) when:

- the ripple reaches **public surface** — a CLI flag, an API route, a config key, a
  serialised format. That is a breaking change, and whether to make it is not yours to
  decide.
- the hit count is **an order of magnitude past expectation** — 200 call sites for a
  "small rename" means the thing is load-bearing and the change needs a plan.
- a survivor reveals that **two parts of the codebase disagreed before you started**. Do not
  quietly pick a winner; that is a separate decision with its own consequences.

---

## Out of scope

Judging whether the change itself is correct — that is review. Enforcing style —
[`coding-standards`](../coding-standards/SKILL.md). Building the mechanical transform:
prefer an AST-aware tool over a text substitution where one exists, and this skill checks
its output either way.

---

## Done when

The changed set came from `git diff` rather than recall; the literal sweep is at zero hits
or every survivor is named as deliberate; the quoted-string form was searched separately;
the semantic sweep covered the artifact classes the ripple list named; the inverse sweep
covered anything moved or renamed; the change was **run**, including any doc example; and
the report says what was left deliberately and what was not checked at all.
