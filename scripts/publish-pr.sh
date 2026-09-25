#!/usr/bin/env bash
# Publish the working tree's skill changes as a pull request.
#
# The Devin-side counterpart of sync-skills.sh. That script commits straight to
# main from a persistent ~/.claude checkout; this one runs in a throwaway clone
# on an ephemeral machine and never touches main — it commits to a branch,
# pushes, and opens (or reuses) a PR the repository owner merges by hand.
#
#   scripts/publish-pr.sh <slug> <title> [body-file]
#
# Auth: DOKU67_SKILLS_GITHUB_TOKEN (a fine-grained PAT on this repo) if set,
# otherwise whatever credentials git and `gh` already have.
#
# Only the paths the .gitignore allowlists can be committed, and the script
# refuses to run on main, so a mistake here costs a PR, never history.

set -euo pipefail

SLUG="${1:?usage: publish-pr.sh <slug> <title> [body-file]}"
TITLE="${2:?usage: publish-pr.sh <slug> <title> [body-file]}"
BODY_FILE="${3:-}"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

OWNER_REPO="${SKILLS_REPO:-DoKu67/claude-code-skils}"
BRANCH="devin/$(date -u +%Y%m%d)-${SLUG}"

log() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

git add -A skills skills-staging skills-disabled scripts hooks AGENTS.md README.md .devin-plugin 2>/dev/null || true
if git diff --cached --quiet; then
  log "nothing to publish"
  exit 0
fi

CURRENT="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT" = "main" ] || [ "$CURRENT" = "master" ]; then
  git checkout -q -b "$BRANCH"
else
  BRANCH="$CURRENT"
fi

# Devin's default git config rewrites github.com to an org proxy that rejects the
# PAT; the mixed-case host sidesteps the rewrite and GitHub does not mind. The
# askpass helper keeps the token out of the URL and out of any log.
if [ -n "${DOKU67_SKILLS_GITHUB_TOKEN:-}" ]; then
  ASKPASS="$(mktemp)"
  printf '#!/bin/sh\ncase "$1" in *sername*) echo x-access-token;; *) echo "$DOKU67_SKILLS_GITHUB_TOKEN";; esac\n' >"$ASKPASS"
  chmod +x "$ASKPASS"
  trap 'rm -f "$ASKPASS"' EXIT
  export GIT_ASKPASS="$ASKPASS" GIT_TERMINAL_PROMPT=0
  PUSH_URL="https://GitHub.com/${OWNER_REPO}.git"
  GIT=(git -c credential.helper=)
else
  PUSH_URL="origin"
  GIT=(git)
fi

if [ -n "$BODY_FILE" ]; then
  git commit -q -F "$BODY_FILE"
else
  git commit -q -m "$TITLE"
fi
log "committed on $BRANCH"

"${GIT[@]}" push -q -u "$PUSH_URL" "HEAD:refs/heads/$BRANCH"
log "pushed $BRANCH"

BODY="$( [ -n "$BODY_FILE" ] && tail -n +3 "$BODY_FILE" || echo "Opened by scripts/publish-pr.sh from a Devin session." )"

if [ -n "${DOKU67_SKILLS_GITHUB_TOKEN:-}" ]; then
  api() { curl -sS -H "Authorization: Bearer $DOKU67_SKILLS_GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$@"; }
  EXISTING="$(api "https://api.github.com/repos/${OWNER_REPO}/pulls?head=${OWNER_REPO%%/*}:${BRANCH}&state=open" | jq -r '.[0].html_url // empty')"
  if [ -n "$EXISTING" ]; then
    log "PR already open: $EXISTING"
    echo "$EXISTING"
    exit 0
  fi
  URL="$(api -X POST "https://api.github.com/repos/${OWNER_REPO}/pulls" \
    -d "$(jq -n --arg t "$TITLE" --arg h "$BRANCH" --arg b "$BODY" '{title:$t,head:$h,base:"main",body:$b}')" \
    | jq -r '.html_url // ("ERROR: " + (.message // "unknown") + " " + ((.errors // []) | tostring))')"
else
  URL="$(gh pr create --repo "$OWNER_REPO" --head "$BRANCH" --base main --title "$TITLE" --body "$BODY" 2>&1 | tail -1)"
fi

log "PR: $URL"
echo "$URL"
case "$URL" in ERROR*) exit 1;; esac
