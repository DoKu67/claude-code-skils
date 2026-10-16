---
name: sequence-diagram
description: "Draw a UML sequence diagram of one happy path — the ordered calls between the components of a system for one scenario, with the tables and stores each step reads or writes named on the arrow — as inline SVG inside a self-contained HTML page, with a subtitle saying what the path does, a numbered title and a legend. Use when the user says \"sequence diagram\", \"happy path\", \"walk me through what happens when\", \"what calls what in order\", or when a plan, spec or design page needs the order of operations for a scenario. Draw the minimal number of paths, one per distinct mode of execution, never one per endpoint."
---

# sequence-diagram

Write and explain with ASD-STE100 at **90% compliance** as a writing target.
Apply the [writing rules](../report/SKILL.md#writing-style) to this skill's prose.

A sequence diagram answers one question: **for one scenario, who calls whom, in what order,
and what data is read or written at each step?** It is read by someone who already has the
block diagram and wants to follow one request through it.

*Why this skill exists:* the user asked for sequence diagrams in 12 sessions and corrected
the same things: "make it UML compliant", "put a subtitle of what the happy path actually
does", "explicitly state what tables we're touching when an action gets, updates, or posts",
"several happy paths but the minimal number", "assume I am a new grad seeing this system for
the first time".

---

## 1. Choose the paths

- **One diagram per distinct mode of execution**, not one per endpoint or per function.
  Two paths that differ only in a parameter are one path.
- Run [`minimal-cover`](../minimal-cover/SKILL.md) over the candidate paths: the goals are
  the behaviours the reader must understand; keep the smallest set that covers them. Say
  which paths were dropped and why.
- The first path is always the main happy path. Error paths are drawn only when the user
  asks, or when the error is the point of the page.

## 2. Name the participants

- Participants are the **components of the block diagram**, with the same names, in the
  same left-to-right order. A participant that is not on the block diagram means one of the
  two figures is wrong.
- Add one lifeline per store the path touches (Postgres, S3, Redis, an outside API).
  Tables are not lifelines; they go on the arrows.
- 4–8 lifelines. More than 8 means the path is two paths, or the components are too fine.

## 3. Draw the messages

- UML notation: solid line, filled arrowhead for a synchronous call; solid line, open
  arrowhead for an asynchronous message (an enqueue, an event); dashed line for a return.
  Activation bars on the callee for the duration of the call.
- **Every arrow is numbered and labelled** with a verb and its object: `3. enqueue
  extraction job`, `5. read sequence_task`, `6. write email_draft`.
- **Name the table or store and the operation on every arrow that touches data**: `read
  sequence (by public_id)`, `insert sequence_task`, `update sequence_task.status`, `put
  s3://bucket/key`. A reader must be able to list every table the path touches from the
  arrows alone.
- When a step forks into parallel work, use a `par` fragment. When a step repeats, use a
  `loop` fragment with its exit condition. Use `alt` only for a branch the path must show;
  otherwise it belongs to another path.
- When the diagram is for a skill or a process rather than code, the participants are the
  roles or the skills, and the messages are the hand-offs between them. Show what is
  passed, not "call skill X".

## 4. Render it

- Inline SVG in a self-contained HTML page (no scripts, no external assets). Never a PNG.
- **A subtitle under the title** that says what the path does in one sentence: "Happy
  path: a user adds a contact and a sequence is generated for it."
- **A numbered title**: "Figure 3. Sequence: generate a sequence from contact data", and a
  legend showing the arrow kinds used.
- Lifeline headers in the block diagram's shapes (rectangle for a service, cylinder for a
  store, dashed box for an outside system), so the two figures read as one.
- Colour-blind safe; shape and line style carry meaning, never colour alone; no purple.
- Readable at 100% zoom; the figure is no wider than the page's text.

## 5. Check before shipping

- Does the subtitle say what the path does?
- Can the reader list every table and store the path touches from the arrows alone?
- Do the participants match the block diagram's names and order?
- Are all arrows numbered, labelled, and in UML notation?
- Was the set of paths minimized, and is the first one the main happy path?

If any answer is no, redo the figure.

## Out of scope

Which components exist and how data flows between them in general — see
[`block-diagram`](../block-diagram/SKILL.md). Tables and keys — see
[`schema-diagram`](../schema-diagram/SKILL.md).

## Done when

The set of paths was minimized to one per execution mode; the participants are the block
diagram's components plus the stores touched; every arrow is numbered, labelled, in UML
notation and names the table or store it touches; the figure has a subtitle, a numbered
title and a legend; it is inline SVG in a self-contained HTML page; and §5 was answered yes
on every line.
