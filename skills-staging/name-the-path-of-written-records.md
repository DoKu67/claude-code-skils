---
id: name-the-path-of-written-records
target: notes
kind: rule
signal: correction
status: staged
occurrences: 2
threshold: 3
---

**Rule:** When a reply reports something that was written to a journal file, name the path —
and the section or line — rather than describing the content. A record the user cannot
locate is one they will ask you to create again.

**Prediction:** If this fires, the user stops asking where a plan, queue or result is
recorded, and stops asking for files that already exist.
**Falsified if:** paths in replies go unread and the user keeps asking anyway, which would
mean the problem is the directory layout rather than the reporting.

**Occurrences**
- 2026-08-03 · session 01PqXfrt · re-prompt · "ok, let's start doing some experiments make an
  experiments.md file" — `journal/experiments.md` already existed, with the frozen-control
  block, the baseline and a four-item queue. It had been created in a batch and mentioned in
  passing, never as a path.
- 2026-08-03 · session 01PqXfrt · re-prompt · "where can I see where runs 2 and 3 are
  planned?" — they were planned in three places (`journal/experiments.md` lines 91–134,
  `journal/notes.md` proposals, `scripts/run_lr_search.sh` header), none of which had been
  cited by path when the plan was reported.

**Contributing cause worth recording.** `ml_logging` places `experiments.md` at the repo
root; `rl-env-mvp` overrides that to `journal/`. The user looked for the file where the
older convention puts it. If this candidate reaches its threshold, the fix may be partly to
reconcile the two skills rather than only to change how paths are reported.
