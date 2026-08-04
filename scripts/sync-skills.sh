#!/usr/bin/env bash
# Commit and push local skill changes to the skills repository.
#
# Safe to run unattended on a timer, on any machine, at any frequency. It is a
# no-op when nothing changed. It never destroys work: no reset --hard, no clean,
# no restore, no force-push. If it cannot reconcile with the remote it stops and
# leaves the local commit in place for a human to look at.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1

log() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
  log "ERROR: not on a branch (detached HEAD or not a git repo). Doing nothing."
  exit 1
fi

# An in-progress rebase or merge from a previous run means a human needs to look
# at this. Touching it would risk the very thing this script must never do.
if [ -d "$(git rev-parse --git-path rebase-merge)" ] ||
   [ -d "$(git rev-parse --git-path rebase-apply)" ] ||
   [ -f "$(git rev-parse --git-path MERGE_HEAD)" ]; then
  log "ERROR: a rebase or merge is already in progress. Resolve it by hand; not touching anything."
  exit 1
fi

# Stage everything. The .gitignore allowlist is what makes this safe: only
# README.md, .gitignore, scripts/ and the three skill directories can ever be
# staged, no matter what else is sitting in ~/.claude.
git add -A

if git diff --cached --quiet; then
  log "no local changes"
else
  SUMMARY="$(git diff --cached --name-only | sed 's|/.*||' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  COUNT="$(git diff --cached --name-only | wc -l | tr -d ' ')"
  if ! git commit -q -m "sync: ${COUNT} file(s) in ${SUMMARY} from $(hostname -s)"; then
    log "ERROR: commit failed"
    exit 1
  fi
  log "committed ${COUNT} file(s): ${SUMMARY}"
fi

# Reconcile with the remote before pushing — another machine may have pushed
# since the last run. The working tree is already clean at this point, so there
# is nothing for the rebase to stash.
if ! git fetch -q origin "$BRANCH" 2>/dev/null; then
  log "fetch failed (offline?). Local commits are safe; will retry next run."
  exit 0
fi

LOCAL="$(git rev-parse @)"
REMOTE="$(git rev-parse "origin/${BRANCH}")"
BASE="$(git merge-base @ "origin/${BRANCH}")"

if [ "$LOCAL" = "$REMOTE" ]; then
  log "up to date with origin/${BRANCH}"
  exit 0
fi

if [ "$LOCAL" = "$BASE" ]; then
  # Remote is ahead and we have nothing new: fast-forward only.
  if git merge --ff-only -q "origin/${BRANCH}"; then
    log "fast-forwarded to origin/${BRANCH}"
  else
    log "ERROR: could not fast-forward"
  fi
  exit 0
fi

if [ "$REMOTE" != "$BASE" ]; then
  # Both sides moved. Rebase local commits on top of the remote.
  if ! git rebase -q "origin/${BRANCH}"; then
    git rebase --abort 2>/dev/null
    log "ERROR: rebase onto origin/${BRANCH} conflicts. Aborted; your commits are intact and unpushed. Resolve by hand."
    exit 1
  fi
  log "rebased onto origin/${BRANCH}"
fi

if git push -q origin "$BRANCH"; then
  log "pushed to origin/${BRANCH}"
else
  log "ERROR: push failed. Commits are safe locally; will retry next run."
  exit 1
fi
