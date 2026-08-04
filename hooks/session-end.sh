#!/usr/bin/env bash
# SessionEnd hook: release this session's edit lock, then sync.
#
# This is the release half of the lock taken by edit-lock.sh, and it is what
# makes deferring cheap — instead of waiting up to six hours for the next timer
# slot, a deferred sync happens seconds after the last session stops editing.

CLAUDE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCKDIR="${CLAUDE_HOME}/.sync-locks"

INPUT="$(cat)"
SESSION="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
SESSION="$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9._-' '_')"

[ -n "$SESSION" ] && rm -f "${LOCKDIR}/session-${SESSION}.edit" 2>/dev/null

# Detached, so ending a session never waits on git or the network. sync-skills.sh
# takes its own lock, so this racing the timer is harmless.
setsid "${CLAUDE_HOME}/scripts/sync-skills.sh" >>"${CLAUDE_HOME}/hooks/sync.log" 2>&1 &

exit 0
