---
name: outline
description: Produce a flat, one-table-per-file inventory of a file or folder's main classes/functions/constants, each with a one-line "what it does". Use when the user asks for a "simplified structure", "just the main objects/methods and what they do", "what's in this file", an overview of a folder without the full nested call graph, or is new to a codebase and wants to get oriented fast. Distinct from /call-tree (nested call graph, every function, inputs/outputs, callees, file:line refs) and /explain (deep single-subject narrative walkthrough) — outline is breadth-first and flat: one row per notable definition, grouped by file, no nesting.
---

# outline

One table per file, one row per thing that matters in it. The value is in staying flat —
a reader scanning several files at once needs "what's here and what's it for," not a call
graph or a narrative. If they want the graph, that's `/call-tree`; if they want the story
of how one thing works, that's `/explain`.

---

## Establish scope

Same as `/call-tree`: accept any combination of files and folders. If the user gestured
vaguely ("the llm stuff", "this module"), resolve it to actual paths and state which ones
you're using in one line before producing anything.

---

## The format

For each file in scope, one heading and one table:

```markdown
## `path/to/file.py`
| Object/Function | What it does |
|---|---|
| `Name` | One line, plain language, says what it DOES |
```

Rules:

- **One table per file**, in the order the files were given (or top-to-bottom reading order
  for a folder — the order a newcomer would naturally open them in, not alphabetical).
- **One row per notable top-level definition**: classes, module-level constants that shape
  behavior, and top-level functions. Do not descend into private/nested helper functions
  unless the file has nothing else of substance.
- **Skip decoratively**: imports, `__all__`, trivial re-exports. An empty or near-empty file
  (like a bare `__init__.py`) gets one line of prose, not a table — "empty, just marks the
  package."
- **Descriptions say what the thing does, never what it is.** "Generates a random unique
  call id" — not "A function that returns a string." If you're restating the type signature
  in words, rewrite it.
- **No nesting, no call graph, no inputs/outputs, no file:line refs.** Those belong to
  `/call-tree` — if the user's next question is "okay but what calls what," point them
  there rather than bolting a call graph onto this table.
- **Reading order beats alphabetical.** Group rows the way someone would encounter them
  scanning the file top to bottom, since that's usually the order dependencies make sense
  in (types before the functions that use them, etc.).

---

## When breadth beats depth

This is for **orientation**, not for auditing correctness or explaining a mechanism — a
first pass over unfamiliar code, or re-grounding after time away from a file. If the actual
question is "why is this done this way" or "walk me through what happens step by step,"
that's `/explain`, not `/outline`. If the question is "what calls what" or "trace this
path," that's `/call-tree`.

A request that names several files or a whole folder and just wants to know what's in each
one, with no follow-up implied, is the clearest signal for this skill.

---

## Where to look

**Read every file in scope in full before writing its table.** Do not infer a file's
contents from its name, its neighbor's pattern, or a prior summary of it from earlier in
the conversation — a file that was read once already may have changed, and a name like
`client.py` says nothing about what's actually inside.

If a file is large enough that "one row per definition" would run past ~15 rows, group
related rows under a sub-heading inside that file's table (e.g. "Validation," "The actual
call") rather than dropping rows silently to hit a count.

---

## Done when

Every file in scope has exactly one table (or one line noting it's empty/trivial); every
description states what the thing does in plain language; nothing is invented that isn't
actually in the file; and a reader could locate anything mentioned by name alone without
needing file:line references.
