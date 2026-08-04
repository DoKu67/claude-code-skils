---
name: checkpoint-commits
description: Commit work at each completed checkpoint without being asked, then offer — without blocking — to keep those commits, squash a chosen set of them, or fold them into one. Use whenever work spans more than one checkpoint: a todo list with several large tasks, a build with staged components, a tuning loop recording runs, any session long enough that losing the last hour would hurt. It reshapes local history only, and never discards work.
---

# checkpoint-commits

Work that is not committed is work that can be lost, and asking permission first is what
makes a safety net useless. **Commit at every checkpoint, immediately, without asking.**

Then, separately and without blocking, ask what shape the history should end up in. The
commit already happened, so nothing is at risk while that question is open — which is the
whole reason the two are separated.

---

## The rule that never bends

**This skill never destroys work.** It reshapes history; it does not remove content. Every
file change that exists before a reshape exists after it.

| Never | Why |
|---|---|
| `git reset --hard` | Discards the working tree |
| `git checkout -- <path>`, `git restore <path>` | Discards one file's changes |
| `git clean` | Deletes untracked files |
| `git revert` | This skill is about *when* to commit, not about undoing decisions |
| Force-push over commits that exist on a remote | Destroys someone else's reference |

`git reset --soft` is the only reset. It moves the branch pointer and leaves every change
staged on disk.

**If the only way to honour a request would lose work, refuse and say which request and
why.** Do not find a clever route to it.

---

## When to commit

**One commit per large task in a todo** is the working heuristic. Beyond that, the moments
that earn a commit are the ones where something became true that was not true before:

- a component passed its gate or its tests went green
- a run finished and its result was recorded
- a sweep, review or consistency pass came back clean
- a decision was written down that the next step depends on

Commit at these points whether or not anyone asked. A checkpoint commit is small, and its
message says what became true — not "wip".

---

## The question, and why it does not block

At a natural pause — and again whenever the checkpoint count gets large — ask which shape
the history should take. Then **keep working while it is unanswered.** The question is
about presentation; the commits are already safe.

| Option | Means | How |
|---|---|---|
| **1. Keep all** | The checkpoint commits are the history | Nothing to do |
| **2. Squash some** | The user picks which ones group together | `git reset --soft <base>`, then re-commit in the chosen groupings |
| **3. Fold into one** | One rolling commit; later checkpoints append to it | `git commit --amend` at each subsequent checkpoint, or `reset --soft` then one commit |

**Do not ask after every commit.** Once per natural pause is the cadence; more than that is
noise, and noise is what makes a non-blocking question start blocking.

### On method versus mechanism

`git rebase -i` is the familiar way to squash and is **unavailable in this harness** —
interactive git is not supported here. `git reset --soft <base>` followed by re-committing
reaches the same end state without an editor, and it cannot lose work, which
`rebase -i` can when it goes wrong. Use it, and say so rather than reporting a rebase that
did not happen.

---

## Pushed commits are frozen

**Once a commit exists on a remote, this skill does not touch it.** Not squashed, not
amended, not folded. Rewriting published history is the one case where reshaping genuinely
destroys something — every clone and every branch that references it.

Reshaping applies only to commits that have never left the machine. When a pause finds a
mix, say which commits are still local and offer to reshape only those.

---

## Out of scope

Whether to push, branch strategy, and release tagging — those are project decisions.
Undoing a change the user no longer wants is a normal edit or a `revert` **they ask for**,
not something this skill initiates.

---

## Done when

Every checkpoint since the last pause has its own commit; the shape question was asked at a
pause and did not block work while it was open; any reshape used `reset --soft` or `--amend`
and left the working tree byte-identical; no pushed commit was rewritten; and nothing was
discarded, reverted or cleaned.
