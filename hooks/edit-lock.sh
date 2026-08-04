#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|NotebookEdit): mark this session as actively
# editing, so the background sync will not commit a half-written file.
#
# Runs before every single edit, so it must be trivially fast: no subprocess
# beyond `sed`, no network, no git. It touches one file and exits.
#
# The marker's mtime is the heartbeat. sync-skills.sh ignores and deletes any
# marker older than STALE_AFTER, so a crashed session cannot block syncing
# forever — a lock nobody can release is worse than no lock.

CLAUDE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCKDIR="${CLAUDE_HOME}/.sync-locks"

# Hook input is JSON on stdin. Pull session_id out without spawning python.
INPUT="$(cat)"
SESSION="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -z "$SESSION" ] && SESSION="unknown-$$"

# Keep the id filesystem-safe; it comes from outside this script.
SESSION="$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9._-' '_')"

mkdir -p "$LOCKDIR" 2>/dev/null
: > "${LOCKDIR}/session-${SESSION}.edit" 2>/dev/null

# A PreToolUse hook that exits non-zero blocks the tool call. Nothing this
# script can fail at is worth blocking an edit over.
exit 0
