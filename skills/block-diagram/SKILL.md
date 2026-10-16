---
name: block-diagram
description: "Draw a system-design block diagram — the running parts of a system and how data moves between them, in the style of a system-design interview (\"Hello Interview\") and UML component notation — as inline SVG inside a self-contained HTML page, with a numbered title and a legend. Use when the user says \"block diagram\", \"system design diagram\", \"architecture diagram\", \"how does this system work at a high level\", asks for a Hello Interview or UML component diagram, or when a plan, spec, experiment plan or report needs a figure of a whole system. Not for a single request's order of calls (that is a sequence diagram) and not for tables and their keys (that is a schema diagram)."
---

# block-diagram

Write and explain with ASD-STE100 at **90% compliance** as a writing target.
Apply the [writing rules](../report/SKILL.md#writing-style) to this skill's prose.

A block diagram answers one question: **what are the running parts, and how does the data
move between them?** It is the high-level design a system-design interview asks for. It is
not an inventory of the code. Files, classes, modules, task types and library names are
evidence for the boxes and arrows; they are never the boxes.

*Why this skill exists:* in 14 sessions the user asked for "a Hello Interview style, UML
compliant block diagram" and then corrected the result in the same ways: "this is way too
specific", "don't put filenames or things like (pydantic)", "a ton of services from top
down and nothing left to right", "why does the block diagram only have services writing to
databases?", "I don't know where half these arrows go". The rules below are those
corrections.

---

## 1. Write the flow before drawing

Write 3–6 numbered steps in plain words, from input to output:

> 1. A user connects Google in the web app. 2. The API saves the integration and starts the
> sync workflow. 3. The workflow enqueues an extraction job. 4. A worker pulls events from
> Google and writes them to the `calendar_event` table.

Every step must be true of the code at the commit you read. If a step cannot be checked,
drop it; do not draw it. The diagram is these steps drawn left to right, and each arrow
carries its step's verb.

## 2. Pick the components

A box is a **runtime component**: something that is deployed, runs, stores, or is called.

| Kind | Examples | Shape |
|---|---|---|
| Client or caller | web app, mobile app, a provider sending webhooks, a cron | rectangle; dashed if outside the system |
| Service | API server, chat service, webhook receiver | rectangle |
| Async channel | SQS queue, Temporal, Redis stream, Kafka topic | chevron (notched left, pointed right) |
| Worker pool | integration workers, agent workers, GPU workers | stacked rectangles |
| Store | Postgres, Redis, S3, Mongo, a Modal Volume | cylinder |
| Outside system | Google APIs, Slack, Twilio, an LLM provider | dashed rectangle with `«external»` |

Rules:

- **5–12 boxes; 15 is the hard limit.** Over the limit, the abstraction is wrong: merge
  boxes by role, or move a sub-flow into its own figure.
- **Never a box:** a file, a module, a class, a function, an API namespace, a task type, a
  table, a single queue name, a library. Put those as at most 4 bullets inside the box they
  belong to, or in a table under the figure.
- **Merge by role.** All queues a flow uses are one chevron. All tables are one cylinder
  that lists the main tables. All providers are one box unless the flow treats them
  differently. Split a box only when its two halves take different arrows.
- **Every store the data touches is on the diagram**, named (Postgres, S3, Mongo,
  Braintrust): "put into the diagrams where the data lives".
- **Same components at every zoom level.** A diagram of a sub-system reuses the parent
  diagram's components and names and shows only the part it uses. Zooming in adds bullets
  and figures, not new kinds of boxes.

## 3. Lay it out

- **Columns in flow order, left to right:** callers → services → async channels → workers
  → stores → outside systems. Top-down stacks of services with no left-to-right flow were
  rejected.
- **Arrows go to the adjacent column.** No arrow skips two columns, and no arrows are
  bundled along the bottom. If an arrow must skip, route it in a clear straight corridor.
- **No backward arrows** except one labelled return or callback.
- **Every queue has a producer arrow in and a consumer arrow out.** A diagram where
  services only write into stores and nothing reads is wrong.
- **One arrow to a group** when a box talks to every member of a group. Draw the group as a
  dashed UML boundary.
- **At most about 1.5 arrows per box.** Every arrow has a short label, a verb or the data
  it carries, and no two arrows share a label.
- **Number the arrows** when the figure is read with a numbered flow or a sequence
  diagram, so the two agree.

## 4. Render it

- Inline SVG in a self-contained HTML page (no scripts, no external assets). Never a PNG
  or a tool-generated image the user cannot edit.
- Shapes: white rectangles with a dark 1.5 px stroke and a bold centered title; cylinders
  for stores; chevrons for channels; stacked rectangles for pools; dashed boxes for outside
  systems. Text never wider than the box; the figure never wider than the page's text.
- Colour-blind safe: shape carries the meaning, colour only repeats it. Never purple, and
  never red against green alone. Prefer blue and orange.
- **A legend on every figure** that shows each shape used and what it means.
- **A numbered title under every figure**: "Figure 1. How a sequence is generated", and a
  one-line caption saying what the reader should see.
- Readable at 100% zoom with no scrolling inside the figure. Give the figure an expand-to-
  full-screen control when the page has more than one.
- Dark mode: use CSS variables for fills and strokes so a theme switch needs no
  regeneration.

## 5. Check before shipping

Read the rendered figure at 100% zoom and answer each line with yes:

- Can a reader who has never seen the system retell the numbered flow from the figure
  alone, in under a minute?
- Are all boxes runtime components, 5–12 of them, with no file, class or library names?
- Do columns run left to right, with every arrow labelled and going to an adjacent column?
- Does every queue have an arrow in and an arrow out, and does every store named in the
  flow appear?
- Is there a legend, a numbered title, and nothing in purple?

If any answer is no, redo the figure. Do not ship it with a note.

## Reusing diagrams found in a repository

A diagram in a README or design doc is a lead, not a source. Check every box and arrow
against the code. Drop what cannot be verified. Cite it as "Based on <doc>, corrected: …".

## Out of scope

The order of calls inside one flow — see [`sequence-diagram`](../sequence-diagram/SKILL.md).
Tables, columns and keys — see [`schema-diagram`](../schema-diagram/SKILL.md). Lifecycle
state machines (state diagrams were dropped by the user as adding little).

## Done when

The flow was written as numbered steps first; every box is a runtime component and there
are at most 12; columns run left to right with labelled arrows to adjacent columns; every
queue has in and out arrows; every store the flow touches is drawn; the figure is inline
SVG in a self-contained HTML page with a legend and a numbered title; the colours are
colour-blind safe; and the §5 check was answered yes on every line.
