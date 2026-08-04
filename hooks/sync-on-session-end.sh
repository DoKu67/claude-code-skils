#!/usr/bin/env bash
# SessionEnd hook: push skill changes as soon as a session ends, rather than
# waiting up to 6 hours for the timer. Not registered by default — see README.md.
#
# Runs on every session end, so it must be fast and must never block. It defers
# entirely to sync-skills.sh, which is already a no-op when nothing changed.

CLAUDE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detached, so ending a session never waits on the network.
setsid "${CLAUDE_HOME}/scripts/sync-skills.sh" >>"${CLAUDE_HOME}/hooks/sync.log" 2>&1 &

# A hook that exits non-zero is reported as an error. There is nothing a failed
# background sync should ever do to the session, so always succeed.
exit 0
