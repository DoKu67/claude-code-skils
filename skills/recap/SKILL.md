---
name: recap
description: Condense arbitrary input — the previous output, a pasted document, a topic, a file, a search result — into a fixed four-section digest: Summary, Key Points, Table, Interesting Notes. Use when the user says "recap", "digest this", "give me the short version of that", "use the previous output", "tell me about X", or hands over content/a topic with no further instruction on shape. Distinct from /tldr, which reports project or task STATUS in Summary/Goal/Blockers/Next-Steps form — recap has no notion of task state, blockers, or next actions; it condenses content, it does not report progress.
---

# recap

One format for condensing anything — a prior answer, a document, a topic you looked up,
a paste with no context — always the same four sections, in this order. The value is in
the fixed shape: a reader who has seen one knows exactly where the headline is, where the
substance is, where the structured facts are, and where the asides are, without reading
prose to find out.

**Target: 30 seconds to read the Summary, a further minute for the rest.** If the source
material genuinely has more substance than that, say so rather than compressing it into
unreadable bullets — but default to compressing hard.

---

## The format

```markdown
Summary:
- <1-2 sentences: the actual finding/conclusion/subject matter itself>
- <bullet: a substantive claim from the source, not a description of the source>
- <bullet: what the reader should pay attention to, and why>

Key Points:
- <bullet>
- <bullet>

Table:
| <field> | <field> |
|---|---|

Interesting Notes:
- <bullet>
- <bullet>
```

**All four headings always appear**, even when a section is thin. Write `None` for Key
Points or Interesting Notes when the source genuinely has nothing further to add. The
Table is the one section that always tries to produce a real table (see below) rather than
falling back to `None`.

---

## What goes in each

| Section | Holds | Never |
|---|---|---|
| **Summary** | 1–2 sentences stating the source's actual conclusion or substance, then bullets for what the reader most needs to know or watch out for | A preamble ("Here's a recap of..."), a restatement of the user's request, or a description of the source's *type* in place of its *content* ("this was an /explain output about X" tells the reader nothing X actually said) |
| **Key Points** | The substantive claims, findings, or decisions in the source, one per bullet, in the source's own priority order | Padding bullets to hit a count, or the same point restated twice |
| **Table** | The source's structured facts laid out as rows/columns — entities vs. attributes, options vs. tradeoffs, before vs. after, a timeline, whatever axes the source actually has | A table that just repeats the Key Points bullets one-per-row with no distinguishing columns |
| **Interesting Notes** | Side findings: caveats, contradictions, surprises, tangents adjacent to the ask worth flagging but not the main point | The core takeaway (that belongs in Key Points), or speculation not grounded in the source |

Four rules that keep it useful:

- **Summary reports what the source says, never what kind of source it is.** "This was a
  recap of an /explain run about X" or "the previous output covered the PR's diff" is a
  description of the *artifact*, not a summary of its *content*, and fails the format even
  though it looks like a summary. Test: could someone act on this bullet without opening
  the source? If not, it's meta-commentary — replace it with the actual conclusion.
- **Five bullets per section is the ceiling**, one line each. A source with more substance
  than that means recap is compressing something that should stay a document — say so.
- **The Table earns its place by having real columns.** If nothing in the source varies
  along more than one axis, that's a sign there's no table to make — write a single row
  noting what would need to vary for a table to apply, don't force one.
- **Never invent structure the source doesn't have.** A source with no numbers, no
  comparison, and no timeline gets a thin Table, not a fabricated one.

---

## Where to look

**Read the actual source; do not recall it.**

| Trigger phrase | Source to read |
|---|---|
| "use the previous output" | The immediately preceding assistant message or tool result in this conversation — read what it actually said, not what you intended it to say |
| "tell me about X" | Whatever already establishes X in this conversation/repo; if nothing does, that's a lookup (WebSearch/WebFetch/Explore), not a recall |
| A pasted block, file, or link | The material itself, in full — not a paraphrase formed while skimming it |
| An open-ended "recap that" with the referent ambiguous | Ask which of the plausible referents is meant, rather than guessing |

A recap written from memory of the conversation over-reports precision — confident details
that were never actually in the source read the same as ones that were. If you're not sure
the source said something, it goes in Interesting Notes as a caveat, or gets left out.

---

## How this differs from /tldr

`/tldr` reports where a piece of *work* stands — it has Goal, Blockers, and Next Steps
because work has state, obstacles, and a next actor. `/recap` condenses *content* — a
document, an answer, a topic — which has none of those. Don't force a recap into
task-status shape by inventing a "next step" for a topic that isn't a task, and don't run
`/tldr` on a document that isn't tracking any work.

If a source turns out to actually be a status report in disguise (an update on a project,
a description of blocked work), that's a signal to suggest `/tldr` instead, not to bend
recap's four sections to fit it.

---

## Out of scope

**This skill prints; it does not write files.** If the user wants the digest kept, that's
a separate ask — write it via `/notes` or `/report` if the project uses one, or a plain
file if asked directly.

---

## Done when

All four headings are present in order; Summary states the source's actual substance (a
reader who hasn't seen the source could act on it) rather than describing what kind of
output it was; `None` appears wherever Key Points or Interesting Notes is genuinely empty;
Summary opens with 1–2 sentences before any bullets; no section exceeds five one-line
bullets; the Table has real columns or explicitly notes there was nothing to tabulate; and
nothing is reported as stated by the source that the source did not actually say.
