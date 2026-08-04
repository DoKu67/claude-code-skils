# hooks

Shell commands Claude Code runs automatically at defined points in a session — before a tool
call, after a file edit, when a session ends. A hook is the only way to make something happen
*every* time; a skill or a memory can ask Claude to do something, but the harness is what
guarantees it.

## How a hook gets installed

Two halves, and both have to travel to a new machine:

| Half | Lives in | Tracked |
|---|---|---|
| The script | `hooks/<name>.sh` | Yes — this directory |
| The registration | the `hooks` key in `~/.claude/settings.json` | **No** — `settings.json` is machine state |

`hooks/hooks.json` closes that gap. It is the tracked copy of the registration, and
`scripts/install-hooks.sh` merges it into `settings.json` on each machine. Run that script
after editing `hooks.json`, or just re-run `scripts/install-sync.sh`, which calls it.

Paths in `hooks.json` use `{{CLAUDE_HOME}}`, replaced with the real directory at install
time — so the same file works on a machine with a different username.

## Adding a hook

1. Write the script in this directory and `chmod +x` it.
2. Register it in `hooks.json` under the right event.
3. Run `scripts/install-hooks.sh`.
4. Start a new session — hooks are read at session start, so a running session won't see it.

## Events

| Event | Fires |
|---|---|
| `SessionStart` | A session begins or resumes |
| `UserPromptSubmit` | You submit a prompt, before Claude sees it |
| `PreToolUse` | Before a tool runs — can block it |
| `PostToolUse` | After a tool succeeds |
| `Stop` | Claude finishes responding |
| `SessionEnd` | The session ends |

`PreToolUse` and `PostToolUse` take a `matcher` naming the tools they apply to (`"Edit|Write"`,
`"Bash"`, `"*"`).

## The rule that matters

**A hook runs on every single occurrence of its event, with your permissions, without asking.**
A slow `PostToolUse` hook on `Edit` taxes every edit for the life of the session; a broken
`PreToolUse` hook can block all work. Keep them fast, make them exit `0` unless you mean to
block, and test by running the script by hand first.

## What's here

| File | Event | Does |
|---|---|---|
| `edit-lock.sh` | `PreToolUse` on `Edit\|Write\|NotebookEdit` | Marks this session as editing, so the sync will not commit a half-written file |
| `session-end.sh` | `SessionEnd` | Drops this session's mark, then kicks a sync |
| `sync.log` | — | Output of `scripts/sync-skills.sh`. Untracked |
| `reflect.log` | — | Output of `scripts/reflect-batch.sh`. **Not written by a hook** — it lives here so both background logs sit together. Untracked |

Together these are the **write side of the sync lock**. `scripts/sync-skills.sh` cannot tell
on its own whether a file is finished — mtime says when a write last happened, not whether
another is coming. Only the editor knows, so the editor is what marks it.

The marker's mtime is a heartbeat, and `sync-skills.sh` deletes any marker older than
`STALE_AFTER` (900s). **A lock nobody can release is worse than no lock**: without expiry, one
crashed session would stop the backup forever, silently.

`edit-lock.sh` runs before *every* edit, so it does nothing but `sed` one field out of stdin
and touch a file. It always exits 0 — a `PreToolUse` hook that exits non-zero blocks the tool
call, and nothing this script can fail at is worth blocking an edit over.

JSON has no comments, so disabled entries live under `_examples`; the installer ignores every
key starting with `_`. To enable one, move it into `hooks` and re-run `scripts/install-hooks.sh`.
