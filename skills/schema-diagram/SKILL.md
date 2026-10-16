---
name: schema-diagram
description: "Draw a database schema diagram — every table as a card with its columns and types, primary and foreign keys marked, and the relations between tables drawn as lines, in the classic Supabase style — plus the non-SQL stores (S3, NoSQL, caches) the schema points to, as inline SVG inside a self-contained HTML page with a numbered title and a legend. Use when the user says \"schema diagram\", \"show me the tables\", \"how do these tables relate\", \"what does the data model look like\", or when a design page needs its data layer drawn. Finds relations in application code when the database declares no foreign keys."
---

# schema-diagram

Write and explain with ASD-STE100 at **90% compliance** as a writing target.
Apply the [writing rules](../report/SKILL.md#writing-style) to this skill's prose.

A schema diagram answers one question: **what data is stored, in which tables and stores,
and how do they point at each other?** The reader is checking a column name or a join, so
the diagram must be complete and exact, not a sketch.

*Why this skill exists:* the user asked for schema diagrams in 9 sessions and corrected the
same things: "I liked the classic Supabase schema diagram", "emphasize the tables, schemas,
column names, datatypes, foreign key relations", "if there are 37 tables, show all 37",
"why are there no lines between the tables", "there are no foreign key constraints, so
you'll need to look through application code", "include a cylinder for the S3 bucket and
list what blobs exist and what SQL fields point to them", "add a legend".

---

## 1. Collect the tables

- **Show every table in scope.** If the scope has 37 tables, draw 37 cards. Never sample.
  If the page would be unreadable, split by domain into several figures, each complete for
  its domain, plus one domain-level overview.
- Read the tables from the source of truth: ORM models, migrations, or `information_schema`.
  Include columns inherited from base classes. Note the commit or database you read.
- For each table: name, every column with its type, the primary key, and every column that
  points at another table or store.
- **Also collect the non-SQL stores** the schema points to: S3 buckets (list the blob kinds
  per bucket), NoSQL tables, caches. Note which SQL columns hold their keys or paths.

## 2. Find the relations

Draw a line only for a relation you can cite. Look for evidence, strongest first:

1. **Declared foreign key** in the column definition.
2. **ORM join** — `relationship(..., primaryjoin=...)`.
3. **Query join or filter** — `.join(B, A.x == B.y)`, `.filter(A.x == B.y)`, `in_(select(...))`.
4. **Write site** — a row built from another table's id: `Log(run_id=task_run.id)`.
5. **Lookup by id** — a function receives `x_id` and resolves it on one column.
6. **Key embedding** — a NoSQL or blob key built from a SQL id: `f"chat:{conversation_id}:..."`.
7. **Naming only** — `<table>_id`, a commented-out FK, a column comment. Cite this alone only
   when it is the column's own documented meaning.

Many codebases declare no foreign keys ("no FK to avoid locking the organization row"). A
diagram with no lines is then wrong, not minimal: find the relations in the code. Record each
relation as `source.column → target.column`, its kind (declared / implicit / blob), and the
file and line of its evidence. Self-references are relations too. Summarize tenant keys that
every table carries (`org_id`, `user_id`) in one note instead of drawing them.

## 3. Lay it out

- **One card per table**: bold table name in the header, one row per column with its type,
  primary key marked, key columns marked. Column order as declared.
- **Lines between cards for every relation.** Line ends show cardinality: a dot on the one
  side, an arrowhead on the many side. Declared keys solid; implicit relations dashed; blob
  pointers dotted.
- **Stores that are not tables are cylinders** (S3, NoSQL, cache) with their blob kinds or
  key shapes listed inside, and dotted lines from the SQL columns that point at them.
- Place related tables next to each other so most lines are short; balance the cards across
  columns; never let a line cross a card.
- **A legend at the top** of the figure that shows the key markers, line kinds and shapes.

## 4. Render it

- Inline SVG in a self-contained HTML page (no scripts, no external assets). Never a PNG.
- Monospace column names and types inside the cards; text never wider than the card; the
  figure never wider than the page's text.
- Colour-blind safe: markers and line style carry meaning; colour only repeats it; no
  purple, no red-against-green alone. Use hex colours, not keywords, so a dark theme can
  remap them.
- **A numbered title**: "Figure 2. Schema: sequences and their tasks", with a one-line
  caption. Give the figure an expand-to-full-screen control when the page has more than one.
- Under the figure, a table guide: one row per table, purpose in at most 6 words, and no
  information already visible in the cards.

## 5. Check before shipping

- Is every table in scope drawn, with every column and type?
- Does every relation found in §2 have a line, with its cardinality ends?
- Are the non-SQL stores drawn, with the SQL columns that point at them?
- Is there a legend at the top and a numbered title under the figure?
- Can the reader answer "which column joins A to B?" from the figure alone?

If any answer is no, redo the figure.

## Out of scope

How the running components exchange data — see [`block-diagram`](../block-diagram/SKILL.md).
The order of operations in one scenario — see
[`sequence-diagram`](../sequence-diagram/SKILL.md).

## Done when

Every in-scope table is a complete card; every cited relation is a line with cardinality
ends and a recorded source; non-SQL stores are drawn with their pointers; the figure is
inline SVG in a self-contained HTML page with a legend at the top and a numbered title; the
colours are colour-blind safe; and §5 was answered yes on every line.
