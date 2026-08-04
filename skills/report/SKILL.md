---
name: report
description: Write the current work up as a markdown report in a fixed five-section research-paper format — Title, Abstract, Background, Method, References — with numbered figures and tables. Use when the user says "report", "write this up", "save this as a report", "make a report out of that"; and whenever the output of another command (/prior-work, /explain, /tldr, a debugging session) needs to become a durable file rather than scrollback.
---

# report

A report is the durable form of something that would otherwise live in a scrollback and be
gone. This skill does not produce the content — it takes whatever was just established and
writes it to a file in one fixed shape.

**It is a sink, not a source.** It composes: `/prior-work` then `/report`, `/explain` then
`/report`, an afternoon of debugging then `/report`. The upstream command decides what is
true; this one decides where it goes and what it looks like. It never researches, re-derives,
or improves on its input. If the upstream did not establish something a section needs, that
section says so.

The value is the fixed shape. A reader who has seen one report knows the goal is in section
2, the prior art is in section 3, and the substance is in section 4 — without reading prose
to find out.

---

## The format

Five sections, always all five, in this order, numbered.

| # | Section | Holds | When empty |
|---|---|---|---|
| 1 | **Title** | The finding or the subject, stated as a claim where there is one | Never empty |
| 2 | **Abstract** | Bullets only — Goal, Estimated Work Time, Potential Blockers, then the substance | Never empty |
| 3 | **Background** | What already existed and what it failed to do | `None — no prior work was surveyed.` |
| 4 | **Method** | The substance, as titled bullets with indented sub-bullets, plus figures and tables | `None.` |
| 5 | **References** | Every source, link, file path and run name the report leans on | Count is `0` |

**Every heading is labelled with its slot name**, numbered, and carries its value after a
colon where the slot has one. Exactly these five lines, exactly this form:

```markdown
# 1. Title: LoRA rank was never the constraint; the learning rate was
## 2. Abstract
## 3. Background
## 4. Method: Paired-seed sweep at fixed rank
## 5. References: 8
```

The label is not decoration — it is what lets a reader landing mid-document know which slot
they are in, and what makes a report greppable across a directory of them.

**An empty section still gets its heading.** An absent *Background* is ambiguous between
"nothing exists" and "nobody looked"; `None — no prior work was surveyed` is not. This is the
same rule as [`tldr`](../tldr/SKILL.md), for the same reason.

### Every bulleted section uses the same two-level shape

Not just section 4. Wherever the report bullets, it bullets like this:

- **Bold title bullet — a short phrase, one line.** It is the claim or the field name.
  - Indented sub-bullets carry the substance, one or two lines each.
  - A sub-bullet that needs a third line is two sub-bullets.

The failure this prevents is a bullet list that is really a paragraph list. A four-line
bullet has a marker but no structure: it cannot be skimmed, and the reader has to parse it to
find out whether it holds a claim or a caveat. **If a bullet wraps past two lines, split
it** — the title goes in the parent, the detail goes underneath.

A reader should be able to read only the bold title bullets, top to bottom, and get the
argument. That is the test for whether the split was done in the right place.

### 1. Title

`# 1. Title: Composable report format for saved command output` — not `# 1. Title: Report`.
Where the report has a finding, the title states it rather than naming the topic:
`# 1. Title: LoRA rank was never the constraint; the learning rate was`. A reader scanning a
directory of reports should collect the conclusions from the filenames.

### 2. Abstract

Bullets, never prose, in the two-level shape above. Three fields lead, always, in this order —
each a bold title bullet with its content underneath:

```markdown
- **Goal**
  - What this work is for, in the user's terms.
- **Estimated Work Time**
  - Remaining effort, or `Done`. A range is fine; a number from nowhere is not.
  - Say what the estimate is based on.
- **Potential Blockers**
  - What could stop this. `None` is a legitimate answer.
  - Unblocked by: the decision, answer or resource that would clear it.
```

A blocker without an unblocker is not a blocker, it is a worry.

Then two to four more title bullets of substance — what was done, what came out, what it
means. A reader who stops after section 2 should be able to say what this is and whether it
worked.

### 3. Background

Previous work: what existed before this, and — the part that earns the section — **where it fell
short**. A background section that only lists prior art is a bibliography; the gap is what
motivates section 4.

Where `/prior-work` ran upstream, its convergence and gaps tables belong here, as
`Table N`. Where nothing was surveyed, say that rather than inventing context.

### 4. Method

The heading names the method after the colon: `## 4. Method: Fixed five-section envelope`.
The slot number and word stay fixed so the shape is recognisable; the name after the colon
says what this particular report's approach was. Name the method, not the topic — `Method:
Paired-seed sweep at fixed rank`, not `Method: Tuning`.

The two-level bullet shape above, applied to the substance — bold title bullet is the claim,
indented sub-bullets are what supports it:

```markdown
- **The envelope is fixed, the content is not.**
  - Five sections always present, numbered, in order.
  - An empty section carries `None` and a reason, never an omission.
- **Figures carry the structure prose cannot.**
  - Every figure numbered and captioned (Figure 1).
  - Every figure referenced from the text at least once.
```

Figures, images and tables are encouraged here — see below.

### 5. References

**The heading carries the count**: `## 5. References: 8`, and it must equal the number of
entries below it. A count in the heading is a cheap integrity check — a reference list that
grew while the number stayed at 3 is visibly stale. With no sources, the heading is
`## 5. References: 0` and the body is `None.`

Every source the report leans on: URLs, file paths, run names, commit hashes, ticket IDs.
**The same two-level shape** — the source is the title bullet, what it supported goes
underneath:

```markdown
- **[MADR](https://adr.github.io/madr/)**
  - Fixed section order and decision-shaped titles.
  - The `superseded-by` pattern, reused for re-reports.
- **`~/.claude/skills/tldr/SKILL.md`**
  - The `None`-in-empty-sections rule.
- **Run `calm-heron` (2026-08-03 15:19)**
  - The 0.155 figure in Table 2.
```

A source that supported exactly one thing still gets one sub-bullet rather than an em-dash
continuation. Uniform shape is what makes the list scannable by source name alone, and it is
what lets a source that turns out to be wrong be traced to everything that leaned on it.

A claim taken from a source gets its reference *where it is used*, not only in this list. The
list is what makes the report re-checkable; the inline attribution is what makes it honest.

---

## Figures and tables

Every figure, image, diagram and table is numbered and captioned. Figures and tables count
separately — `Figure 1`, `Figure 2`, `Table 1` — as in a paper.

**The label always goes below** — figures and tables alike, with no exception. Uniform
placement means a reader never hunts for which side the caption is on, and a label that
follows its object always describes the thing directly above it.

**The object and its label are both centered**, together, in one wrapper:

```markdown
<div align="center" style="display:flex; flex-direction:column; align-items:center;">

| # | Section | When empty |
|---|---|---|
| 3 | Background | `None — no prior work was surveyed.` |

**Table 1: Section slots and their empty values**<br/>Every slot appears even when empty, so a missing section is never ambiguous.

</div>
```

```markdown
<div align="center" style="display:flex; flex-direction:column; align-items:center;">

![Report section slots](figs/report-slots.svg)

**Figure 1: Proposed Report Structure**<br/>The five slots and what fills each. Only the envelope is generated by `/report`.

</div>
```

**The description stays on the same source line as the `<br/>`.** A newline after it renders
as a paragraph-sized gap in some previewers rather than a single line break, which separates
a label from its own description. Long caption lines in the source are the price.

Three things in that wrapper are doing work, and dropping any one of them breaks it:

- **The blank lines inside are load bearing.**
  - They close the HTML block, so the markdown within still parses.
  - Without them the pipe table renders as literal text and backticks stay backticks.
- **`align="center"` centers the caption text; it does not center a table.**
  - It maps to `text-align: center`, which only moves inline content.
  - A `<table>` is block-level, so it stays hard left however centered its text is.
- **The flex column is what actually centers the table.**
  - `align-items: center` shrinks each child to its content width and centers it.
  - Both attributes stay: GitHub strips inline `style` and honours `align`; most local previewers do the reverse.

**The exception is a figure drawn in a code block.** ASCII diagrams, tree output and terminal
captures stay outside the wrapper, left-aligned, with only the label centered below them —
`align="center"` centers each line of a `<pre>` independently, which pulls a box diagram
apart. A centered label under a left-aligned block is the correct trade; a shredded diagram is
not.

```markdown
​```
   ┌──────────┐
   │  intact  │
   └──────────┘
​```

<div align="center" style="display:flex; flex-direction:column; align-items:center;">

**Figure 2: A diagram that survives**<br/>Code-block figures keep their own alignment; only the label centers.

</div>
```

Three rules:

- **Reference every figure from the text at least once** — "the envelope is fixed (Figure 1)".
  A figure nobody references is decoration, and it is the first thing that goes stale.
- **The caption is readable alone.** Someone flipping through the figures should understand
  each one without the surrounding prose.
- **Numbering runs in document order** and never renumbers silently. If a figure is inserted,
  every later reference is updated in the same edit — see [`consistency`](../consistency/SKILL.md).

---

## Frontmatter and filename

```yaml
---
title: Composable report format for saved command output
date: 2026-08-04T14:32:07-07:00
source: /prior-work          # the command this wraps, or "conversation"
inputs:                      # what was actually read to produce it
  - https://adr.github.io/madr/
  - ~/.claude/skills/tune-report/SKILL.md
tags: [skills, formats]
supersedes:                  # prior report on the same subject, if any
---
```

`source` and `inputs` are the fields that make an agent-written report checkable later — they
say what produced it and what it saw. Standard document formats record `author` and `date` and
stop there, which is enough for a human-written memo and not enough for this.

**Filename:** `reports/YYYY-MM-DD-HHMM-<slug>.md`, in the current project, slug from the
title — `reports/2026-08-04-1432-composable-report-format.md`. The time is to the minute
because more than one report a day on the same subject is normal, and a date-only name makes
the second one a collision instead of a sequence. 24-hour clock, local time, matching the
`date` field in the frontmatter.

**Never overwrite.** A second report on the same subject is a new dated file carrying
`supersedes:` for the old path; append `> Superseded by <new path>` to the top of the old one.
The earlier reasoning is the part worth keeping — same principle as
[`notes`](../notes/SKILL.md), which never rewrites history.

Both of these are defaults. If the user names a path, use it.

---

## Traps

- **Filling a section because it is empty.** Inventing background nobody surveyed, or a
  blocker nobody found, is worse than `None` — it reads as established and it is not.
- **Reporting the conversation instead of the state.** The scrollback holds intentions
  alongside outcomes and they look alike in hindsight. Something is done when it ran and the
  output was seen; everything else is an estimate in section 2.
- **Letting section 4 become prose.** The moment the titled-bullet structure dissolves into
  paragraphs, the report stops being scannable and becomes an essay with a header.
- **A figure that duplicates a table.** Pick one. Two views of identical data double the
  maintenance and halve the trust when they drift.
- **Smoothing the failures.** A negative result — a direction closed, an approach that did not
  work — belongs in the Abstract at full size, not softened into a Method sub-bullet.

---

## Out of scope

Producing the content — that is whatever ran before this. This skill will not run a search,
read a codebase, or re-derive a result to fill a section.

[`tldr`](../tldr/SKILL.md) prints a 30-second status and writes no file; if it takes longer
than that to read, it was a report. [`notes`](../notes/SKILL.md) keeps the running record —
`notes.md`, `learnings.md`, `experiments.md` — which is appended to continuously; a report is
a standalone document written once. When the subject is a hyperparameter search, the
deliverable is [`tune-report`](../tune-report/SKILL.md), whose grid and coverage tables are
the point; a report may quote one but does not replace it.

---

## Done when

All five headings are present in order and each is labelled with its slot name and number —
`Title:` and `Method:` carrying their values, `References:` carrying a count that matches the
list below it; `None` and a reason appear wherever a section is empty; the title states the
finding rather than the topic; the Abstract leads with Goal, Estimated Work Time and
Potential Blockers as bullets and every blocker names its unblocker; section 4 is titled
bullets with indented sub-bullets and no bullet wraps past two lines; every figure and table
has a numbered ID, a title and a description **below** it, with object and label wrapped
together in a centered `<div>` — except code-block figures, where only the label centers —
and is referenced at least once from the text;
References lists every source with what it supported; frontmatter carries `source` and
`inputs`; the file is written to `reports/YYYY-MM-DD-HHMM-<slug>.md` and nothing was
overwritten; and nothing appears in the report that the upstream work did not establish.
