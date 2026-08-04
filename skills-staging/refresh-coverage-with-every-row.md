---
id: refresh-coverage-with-every-row
target: tune-loop
kind: rule
signal: correction
status: staged
occurrences: 1
threshold: 3
---

**Rule:** Step 6 of the iteration refreshes the **coverage table** along with the row and the
read. The coverage table is a decision input during the loop, not a report artifact at the
end of it.

**Why this is a gap and not an oversight.** `tune-loop` step 6 says "Append the row to
`experiments.md`. Then write the read in `notes.md`." The coverage table appears exactly once
more in the skill, at **Stopping** — "Then produce the report: the grid, the coverage table
naming every untested axis value". So nothing owns it between the first run and the last, and
the table sits describing the state before the search started.

That is the wrong half of the loop. Coverage is what step 7 reads to decide *which axis
next*, and what tells a reader whether a value is settled or merely defaulted. A coverage
table refreshed only at the end is rewritten from memory rather than maintained, and in the
meantime it actively misleads.

**Prediction:** If this fires, the coverage table never contradicts the run rows above it,
and "what is untested" is answerable at any point in the loop rather than only after it.
**Falsified if:** refreshing per row is pure churn — the table changes only in ways the rows
already made obvious — or the `untested` column stops being read when choosing the next axis.

**Occurrences**
- 2026-08-03 · session 01PqXfrt · correction · "why did this failure happen?" — after two
  runs had landed at 1e-5 (0.313) and 3e-5 (0.660), the coverage table still read
  `learning rate | 1.0e-6 (demo only) | nothing is known here` and asserted "Every axis in
  this block has one value tried, which means every axis is untested." Both rows had been
  appended per step 6 and both reads written; nothing in the iteration told me to touch
  coverage. The table lied in the direction that makes a search look *less* complete than it
  is, which is the failure a coverage table exists to prevent.

**Related.** The same refresh would have caught two other stale cells found at the same time:
`prompts per step` was listed as untested when peak memory at 80% had made it **blocked**,
and the `generation cap` row did not record that p50 had fallen to 222 tokens against a 512
cap — a free saving nobody had taken.
