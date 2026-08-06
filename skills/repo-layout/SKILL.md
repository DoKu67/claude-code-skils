---
name: repo-layout
description: Decide where a file belongs and keep the repository navigable — the root-directory budget, where superseded documents go, the split between importable modules and runnable recipes, and when dead code is archived rather than left in place. Use when adding a file and the location is not obvious, when naming a package or module, when a document is superseded, when a directory has started mixing live and dead code, and when a newcomer could not tell which files still matter. Also use when the user says "this is disorganized", "where should this go", or "clean up the repo".
---

# repo-layout

A newcomer — or you in three weeks — should be able to open the repository and tell, without
reading any code, **what matters now and what is history**. That is the whole job.

Layout rots in a specific way: nothing is ever in the wrong place at the moment it is created.
The scorer belonged in `scripts/` when it was a one-off. The old plan belonged in the root when
it was the plan. Rot is the accumulation of files that were correctly placed once and were never
moved when their role changed.

## The root directory is a lobby, not a warehouse

Everything in the root claims to be important, because that is what being in the root means.

- **Budget: roughly five or six documents.** Past that, a reader cannot tell which to open
  first, and the answer is not a better README — it is fewer files.
- **A superseded document must not sit beside a live one.** Two plans in a root, one of them
  dead, means every reader must first work out which is which. Give history its own place.
- **Config and manifests are exempt** — `pyproject.toml`, `environment.yml`, `.gitignore` and
  their kin are expected in the root and cost a reader nothing.

Signs the root has outgrown itself: a document that only makes sense after reading another one,
two files whose names differ by a suffix, or a file no one has opened since it was written.

## Where history goes

Superseded material is evidence. Deleting it destroys the record of why the current approach
exists; leaving it in place destroys the reader's ability to navigate. Pick one convention per
repository and hold it:

| Convention | Fits when |
|---|---|
| `NAME_deprecated.md` beside the live file | one or two superseded documents, and the pairing is the point |
| An `archive/` or `docs/history/` directory | more than two, or the history spans several kinds of file |

Either way: **the superseded document's own first line says it is superseded and points
forward.** A reader who arrives via search rather than via the directory listing gets no benefit
from where the file sits.

**Renaming ripples further than expected.** Docstrings, journal entries, the auto-loaded context
file, other documents, test names, CI paths. Run [`consistency`](../consistency/SKILL.md)
afterwards and verify every link still resolves — a dead link in a document is worse than a
missing document, because nothing fails.

## Modules, recipes and tests

Three roles, and conflating them is what makes a codebase hard to change.

| Role | Lives in | Test |
|---|---|---|
| **Module** — imported by other code, has a public surface | the package directory | something else imports it |
| **Recipe** — a run built on top of modules: a sweep, an ablation, a one-off investigation, a demo | `scripts/` | nothing imports it |
| **Test** | `tests/`, integration under `tests/integration/` | it asserts |

**A recipe that needs different behaviour composes the modules differently; it does not add a
parameter to a module.** That rule is what stops "just one more flag" from accreting onto a
component that had a clear job, and it keeps the module's public surface honest, because a
recipe can only reach what the module actually exposes.

Split unit from integration tests by **what makes them fail**: a unit test goes red when one
component's behaviour changes, an integration test when an interface between two moves. A red
run then localises the fault before you have read a line.

## Naming

**Name a package for what it contains or does, never as an initialism of the repository.**
`qrl` for `question_rl` tells a reader nothing; `graders` tells them what is inside. The import
line is read far more often than the directory listing, so optimise that:
`from graders.discrimination import score_item` should be a sentence about the code.

Two traps:

- **Do not name a thing for a role it has not earned.** A package called `reward_functions`
  before anything is validated as a reward asserts the conclusion of the work it contains.
  Name for the subject matter, which stays true either way.
- **Rename early or not at all.** Before there is code, a rename is a few lines of documentation.
  After, it is every import, every docstring and every reference.

## Dead code

Code that no longer runs is not free — it is read, searched, and mistaken for live code.

- **A directory must not silently mix live and dead.** If half of `scripts/` belongs to an
  approach that closed, the reader has no way to tell which half.
- **Prefer git history to a commented-out block.** The block is invisible to search-and-replace
  and rots against the code around it.
- **Where dead code is kept deliberately** — provenance, a closed line of work someone may
  revisit — say so at the top of the file in one line, and say what closed it. Otherwise the next
  person re-derives the answer.

## Out of scope

How code is written inside a file — [`coding-standards`](../coding-standards/SKILL.md). What the
plan document contains — [`plan-doc`](../plan-doc/SKILL.md). What the journal contains —
[`notes`](../notes/SKILL.md). What the auto-loaded context file contains —
[`project-brief`](../project-brief/SKILL.md). This skill only decides **where a file goes and
what it is called**.

## Done when

The root holds only live documents plus config; every superseded file is either suffixed or
archived by one consistent convention and says so in its own first line; nothing importable
lives in `scripts/` and nothing in the package is unimported; unit and integration tests are
separated by what makes them fail; every package name describes its contents rather than
abbreviating the repository; no directory mixes live and dead code without saying which is
which; and after any rename, `consistency` has run and every link resolves.
