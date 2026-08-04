---
name: call-tree
description: Prints a static function call tree for a file, folder, set of files/folders, or a whole repository — showing each function's inputs, outputs, and what it does. Use whenever the user asks for a call tree, call graph, "what calls what", the flow through a module, or a map of an unfamiliar codebase. Read-only: never modifies, imports, or runs the analyzed code.
---

# call-tree

Produce a terminal call tree for a requested scope. Every function is shown with its signature (inputs and return type), its source location, and a one-line description of what it does, nested under whatever calls it.

## Hard constraint: read-only

This skill only reads. It must never:

- Edit, create, delete, or reformat any file in the analyzed project.
- Import or execute the analyzed code — no `import`, no running the test suite, no dynamic tracers like `sys.settrace`, `pycallgraph`, or `coverage`. Importing a module runs its top-level code, which is a side effect on the user's system.
- Install packages or add dependencies to the project.

The bundled script parses source with Python's `ast` and never imports the target. Any scratch files (such as the annotations file below) go in `/tmp`, never in the user's repository.

## 1. Establish scope

Accept any combination of files and folders, or the whole repository. Multiple paths in one run are fine — `src/orders/loader.py src/billing/` is a valid scope, and the tree is built across all of them together.

Resolve the scope before running anything:

- If the user named paths, use them exactly.
- If the user gestured vaguely ("this module", "the auth stuff"), find the matching paths and state which ones you are using in one line before running.
- If the scope is the entire repository and it is large (say, more than ~200 Python files), run it with `--compact` first so the output stays readable, then re-run the full format on whichever subsystem the user wants to look at closely.

Cross-scope calls resolve only within the scope you pass. A function in `src/billing/` that calls into `src/orders/` will show as an external call unless both are in scope — mention this if you are analyzing a single file that clearly calls into its siblings.

## 2. Run the script

```bash
python3 <skill-dir>/scripts/call_tree.py PATH [PATH ...] [options]
```

Run it from the repository root so paths in the output are repo-relative. Standard library only, Python 3.9+, nothing to install.

| Option | Effect |
| --- | --- |
| `--depth N` | Maximum nesting depth (default 6). Lower it for an overview, raise it to follow a deep chain. |
| `--include-external` | Also show calls to code outside the scope — stdlib, third-party, and anything in files you did not pass. Hidden by default because it triples the output. |
| `--compact` | One line per function instead of the Input/Output block. Use for large scopes where the full form would run to thousands of lines. |
| `--max-nodes N` | Stop after N nodes (default 400) rather than flooding the terminal. |
| `--repeat-subtrees` | Re-expand a function everywhere it appears instead of collapsing repeats. |
| `--annotations FILE` | Overlay descriptions from a JSON file (see below). |
| `--list-undocumented` | Print the keys of functions that have no docstring. |
| `--json` | Emit the raw graph instead of a tree, for further processing. |

### Output format

Each function shows its name, a description, its inputs, and its outputs, with callees nested beneath:

```
src/orders/filters.py
├── filter_by_age
│   # Drops records older than the cutoff.
│   Input: (records: list[dict], max_age_days: int)
│     * src/orders/filters.py:1
│   Output: list[dict]
│   └── _cutoff
│       Input: (max_age_days: int)
│         * src/orders/filters.py:6
│       Output: int
└── stream_ids
    # Yields each record id in order.
    Input: (records: list[dict])
      * src/orders/filters.py:9
    Output: 'Iterator[str]'  (generator)
```

The bullet under `Input:` is the definition site — the file and line to jump to. `Output:` is the return type only. Two variants:

- `Output: (unannotated)` — the function returns a value but has no return type hint.
- `(generator)` after the type — the function yields.

Markers on the name line:

- `⟲ recursive` — already an ancestor in this branch; the branch stops there.
- `⟲ expanded above` — already shown in full elsewhere in the tree.
- `? one of N definitions` — several in-scope functions share this name and static analysis cannot tell which is called. All candidates are shown.
- `[external]` — called but not defined in scope.

## 3. Fill in the missing descriptions

The script uses each function's docstring summary as its description. Functions without docstrings show no description line, and a tree that is half-annotated is much less useful than a fully annotated one.

So: run `--list-undocumented`. If it returns anything, read those functions, write a one-line description for each into a JSON file in `/tmp`, and re-run the script with `--annotations`.

```json
{
  "src/orders/filters.py::_cutoff": "Computes the cutoff id from the age window.",
  "src/orders/loader.py::OrderLoader.validate": "Checks every record carries an id, raising on the first bad one."
}
```

Keys are exactly what `--list-undocumented` prints: `relative/path.py::Qualified.name`.

Descriptions should say what the function *does*, in one line under ~100 characters. Do not restate the signature — the signature is already on the line above. Note real side effects (writes to disk, mutates its argument, calls the network) because those are what a reader scanning a tree needs to catch.

If the undocumented list is very long (say, over 60 functions), don't read every one. Annotate the functions that appear in the tree — entry points and their first two or three levels — and tell the user that deeper leaves are showing docstrings only.

## 4. Present the result

Print the final annotated tree, then add a short read of it — three or four bullets at most:

- The real entry points, and what each one is for.
- Anything structurally notable: a function called from many places, an unexpectedly deep chain, a cycle, a cluster with no callers (possible dead code).
- Any `?` ambiguities the user should resolve by eye, since those are the places the tree may be wrong.

Do not narrate the mechanics of running the script. The tree and the read of it are the deliverable.

## Non-Python codebases

The script is Python-only. For other languages, build the same tree by reading the source directly and render it in exactly the format shown under **Output format** above — name line, `#` description, `Input:` with the definition site, `Output:` with the return type, callees nested beneath, `[external]` for anything outside the scope. Keep the scope tight when doing this by hand; reading a whole repo this way is slow and error-prone, so ask the user to narrow it rather than guessing at a large tree.

## What this cannot see

Say so plainly when it matters, rather than letting the user treat the tree as complete:

- Calls resolve **by name**. `self.parse()`, `handler.parse()`, and a bare `parse()` all match any in-scope definition named `parse`; if there are several, all are shown as candidates.
- Dynamic dispatch is invisible: `getattr(obj, name)()`, callbacks passed as arguments, registry and plugin lookups, and anything reached only through a decorator wrapper.
- Inheritance is not resolved — a call to an inherited method matches the base class definition only if that definition is in scope.
- Nothing here reflects runtime frequency or which branches actually execute.

This makes the tree an excellent map and a poor safety proof. If the user is about to delete something the tree shows as uncalled, tell them to confirm with a grep for the name first.
