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

| File | Registered | Does |
|---|---|---|
| `sync-on-session-end.sh` | No — opt in | Pushes skill changes when a session ends, instead of waiting for the 6-hour timer |

To turn it on, move the `SessionEnd` block from `_examples` into `hooks` in `hooks.json`, then
run `scripts/install-hooks.sh`. JSON has no comments, so disabled entries live under
`_examples`; the installer ignores every key starting with `_`.
