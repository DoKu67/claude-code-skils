#!/usr/bin/env bash
# Batch-reflect over the session transcripts that have not been read yet.
#
#   reflect-batch.sh              run a pass
#   reflect-batch.sh --dry-run    show what would be read; invoke nothing
#   reflect-batch.sh --status     summarise the state file
#   reflect-batch.sh --mark-seen  record every current session as read WITHOUT
#                                 reading it — starts the loop from today and
#                                 leaves the backlog for a deliberate pass
#   reflect-batch.sh --limit N    cap sessions per pass (default 8)
#
# ---------------------------------------------------------------------------
# The transcripts ARE the queue.
#
# There is deliberately no list of pending work. This scans projects/*/*.jsonl
# and diffs against a state dictionary keyed by session id, so a session the
# SessionEnd hook never recorded, or one that predates this script, is still
# found. A marker file would be a second source of truth that can drift from
# the first; the only way to be wrong here is for a transcript to not exist.
#
# Two properties come from the prior-work survey and are the reason this is a
# dictionary rather than a "last processed" timestamp:
#
#   1. Sessions end concurrently and out of order. A watermark silently skips
#      any session that ended before the mark but was written after it.
#   2. A transcript grows. A session resumed after being reflected keeps its
#      id and gains lines, so the state has to record HOW MUCH was read, not
#      merely that it was.
#
# Staleness is decided by line count plus a hash of the lines already read —
# never by mtime, which moves under `git checkout`, `rsync` and restore-from-
# backup without the content changing (and fails to move when it should).
#
# ---------------------------------------------------------------------------
# At-least-once, on purpose.
#
# State is recorded only after a pass succeeds. A crash mid-pass re-reads those
# sessions next time. That is the safe direction for everything except our own
# occurrence counter, which increments and gates promotion — so a re-read can
# walk a candidate toward its threshold on one real occurrence.
#
# The second half of that defence lives in `reflect` itself: an occurrence whose
# (session id + quote) is already recorded must not be appended again. Until
# that exists, treat the first passes as proposals to read rather than counts to
# trust, and prefer --dry-run.

set -uo pipefail

CLAUDE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Overridable so the classifier can be tested against a fixture directory
# without touching the real state or the real transcripts.
STATE="${REFLECT_STATE:-${CLAUDE_HOME}/reflect-state.json}"
PROJECTS="${REFLECT_PROJECTS:-${CLAUDE_HOME}/projects}"
LOCKDIR="${CLAUDE_HOME}/.sync-locks"

# A transcript still being appended to is a live session. Reading one is not
# harmful — the line count means the next pass picks up the rest — so this is a
# threshold for how *parked* a session must look before it is worth reading.
#
# An hour rather than a few minutes because the pass runs during working hours,
# not only overnight. A correction read out of a session someone is still in can
# be superseded by what they do twenty minutes later, and the pass cannot know
# that. Waiting an hour means a session is usually abandoned rather than paused.
QUIET_SECONDS=${QUIET_SECONDS:-3600}

# A session below this many records has no room for a correction. The count is
# every `"type":"user"` line, harness-injected ones included, so it is a coarse
# floor and not the signal filter — `reflect` does the real filtering.
MIN_TURNS=${MIN_TURNS:-5}

LIMIT=8
MODE=run

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)   MODE=dry ;;
    --status)    MODE=status ;;
    --mark-seen) MODE=mark ;;
    --limit)     LIMIT="${2:-8}"; shift ;;
    -h|--help)   sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required"
[ -d "$PROJECTS" ] || fail "no transcripts directory at ${PROJECTS}"

mkdir -p "$LOCKDIR"

# The timer, a manual run and a SessionEnd-triggered run can collide. Two passes
# incrementing the same candidate file is how a count ends up wrong, and a wrong
# count is what promotes a rule.
if [ "$MODE" = run ] || [ "$MODE" = mark ]; then
  exec 9>"${LOCKDIR}/reflect.lock"
  if ! flock -n 9; then
    log "another reflect pass is already running; nothing to do"
    exit 0
  fi
fi

[ -f "$STATE" ] || printf '{"version":1,"sessions":{}}\n' > "$STATE"
jq empty "$STATE" 2>/dev/null || fail "state file is not valid JSON: ${STATE}"

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
mtime_of() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
prefix_sha() { head -n "$2" "$1" | sha256sum | cut -d' ' -f1; }

# ------------------------------------------------------------------- scan --
#
# Classify every transcript against the state dictionary. Emits TSV:
#   session-id  project  path  total-lines  from-line  verdict

scan() {
  local now; now="$(date +%s)"
  local f sid project lines turns mt known_lines known_sha

  for f in "$PROJECTS"/*/*.jsonl; do
    [ -f "$f" ] || continue
    sid="$(basename "$f" .jsonl)"
    project="$(basename "$(dirname "$f")")"

    mt="$(mtime_of "$f")"
    [ -n "$mt" ] && [ $(( now - mt )) -lt "$QUIET_SECONDS" ] && continue

    lines="$(wc -l < "$f" | tr -d ' ')"
    [ "$lines" -gt 0 ] 2>/dev/null || continue

    # grep -c prints 0 and exits 1 when nothing matches, so `|| echo 0` would
    # append a second zero and break the comparison below.
    turns="$(grep -c '"type":"user"' "$f" 2>/dev/null)"
    turns="${turns:-0}"
    if [ "$turns" -lt "$MIN_TURNS" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$project" "$f" "$lines" 0 too-short
      continue
    fi

    known_lines="$(jq -r --arg s "$sid" '.sessions[$s].lines // empty' "$STATE")"

    if [ -z "$known_lines" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$project" "$f" "$lines" 1 new
      continue
    fi

    if [ "$lines" -lt "$known_lines" ]; then
      # Fewer lines than we read. The file was truncated or rewritten, so its
      # identity no longer matches what the state describes. mbsync hits the
      # same case as a UIDVALIDITY change and its advice is a full resync; ours
      # would mean re-reading the session and inflating its occurrences, so this
      # reports and stops instead of guessing.
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$project" "$f" "$lines" 0 diverged
      continue
    fi

    known_sha="$(jq -r --arg s "$sid" '.sessions[$s].prefix_sha256 // empty' "$STATE")"
    if [ -n "$known_sha" ] && [ "$(prefix_sha "$f" "$known_lines")" != "$known_sha" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$project" "$f" "$lines" 0 diverged
      continue
    fi

    if [ "$lines" -gt "$known_lines" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$sid" "$project" "$f" "$lines" "$(( known_lines + 1 ))" resumed
    else
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$project" "$f" "$lines" 0 done
    fi
  done
}

# Record one session as read up to $2 lines, with $3 as the outcome.
record() {
  local sid="$1" path="$2" lines="$3" outcome="$4" project="$5" tmp
  tmp="$(mktemp "${STATE}.XXXXXX")"
  jq --arg s "$sid" \
     --arg p "$project" \
     --argjson l "$lines" \
     --arg h "$(prefix_sha "$path" "$lines")" \
     --arg t "$(now_iso)" \
     --arg o "$outcome" \
     '.sessions[$s] = {project:$p, lines:$l, prefix_sha256:$h, reflected_at:$t, outcome:$o}
      | .updated = $t' \
     "$STATE" > "$tmp" && mv "$tmp" "$STATE" || { rm -f "$tmp"; fail "could not write ${STATE}"; }
}

# ----------------------------------------------------------------- status --

# One scan per invocation — it greps every transcript, so calling it per verdict
# would read the whole corpus several times over.
SCAN="$(scan)"

if [ "$MODE" = status ]; then
  printf 'state: %s\n\n' "$STATE"
  jq -r '"recorded sessions: \(.sessions | length)\nlast updated:      \(.updated // "never")"' "$STATE"
  printf '\n%-10s %s\n' "VERDICT" "COUNT"
  printf '%s\n' "$SCAN" | cut -f6 | sort | uniq -c | awk '{printf "%-10s %s\n", $2, $1}'
  printf '\npending detail\n'
  printf '%s\n' "$SCAN" | awk -F'\t' '$6=="new"||$6=="resumed"||$6=="diverged" {printf "  %-10s %-42s %s (from line %s of %s)\n", $6, $2, $1, $5, $4}'
  exit 0
fi

# -------------------------------------------------------------------- run --

PENDING="$(printf '%s\n' "$SCAN" | awk -F'\t' '$6=="new"||$6=="resumed"')"
DIVERGED="$(printf '%s\n' "$SCAN" | awk -F'\t' '$6=="diverged"')"

if [ -n "$DIVERGED" ]; then
  log "WARNING: transcripts diverged from recorded state — not read, not recorded:"
  printf '%s\n' "$DIVERGED" | awk -F'\t' '{printf "           %s  %s\n", $2, $1}'
  log "         re-read one by hand, or clear its entry from ${STATE} to reprocess"
fi

if [ -z "$PENDING" ]; then
  log "no unreflected sessions"
  exit 0
fi

BATCH="$(printf '%s\n' "$PENDING" | head -n "$LIMIT")"
TOTAL="$(printf '%s\n' "$PENDING" | wc -l | tr -d ' ')"
TAKEN="$(printf '%s\n' "$BATCH" | wc -l | tr -d ' ')"

if [ "$TAKEN" -lt "$TOTAL" ]; then
  log "${TOTAL} sessions pending; reading ${TAKEN} this pass (--limit ${LIMIT}), rest next run"
else
  log "${TAKEN} session(s) to reflect"
fi

if [ "$MODE" = mark ]; then
  printf '%s\n' "$PENDING" | while IFS=$'\t' read -r sid project path lines from verdict; do
    record "$sid" "$path" "$lines" marked-seen "$project"
    printf '  marked seen  %-42s %s\n' "$project" "$sid"
  done
  log "recorded ${TOTAL} session(s) as read without reading them"
  exit 0
fi

# The prompt names each transcript and the line to resume from, so a resumed
# session contributes only its new turns rather than being counted twice.
FILELIST="$(printf '%s\n' "$BATCH" | awk -F'\t' \
  '{printf "- %s  (read from line %s of %s; session id %s)\n", $3, $5, $4, $1}')"

PROMPT="/reflect

Batch pass over sessions that have not been reflected yet. Read ONLY these transcripts,
each from the line given — earlier lines were read by a previous pass and must not be
counted again:

${FILELIST}

Follow the skill exactly. Only \`type == \"user\"\` records, minus the harness-injected
prefixes. Before appending an occurrence, check the candidate does not already record that
same session id with that same quote; if it does, skip it rather than incrementing.

Stage or increment candidates in ~/.claude/skills-staging/ and update LEDGER.md. Do not
edit anything under ~/.claude/skills/ — promotion is codify's job and needs approval.

Because several sessions are read at once, say for each candidate how many DISTINCT
sessions it appeared in, and name anything that crossed its threshold."

if [ "$MODE" = dry ]; then
  printf '\n--- would read ---\n%s\n' "$FILELIST"
  printf -- '--- prompt ---\n%s\n\n' "$PROMPT"
  log "dry run: nothing invoked, state unchanged"
  exit 0
fi

log "invoking claude"
if timeout 1800 claude -p "$PROMPT" \
     --permission-mode acceptEdits \
     --add-dir "$CLAUDE_HOME" \
     2>&1; then
  printf '%s\n' "$BATCH" | while IFS=$'\t' read -r sid project path lines from verdict; do
    record "$sid" "$path" "$lines" processed "$project"
  done
  log "recorded ${TAKEN} session(s) as read"
else
  # Nothing is recorded, so the next pass retries. At-least-once, by choice:
  # losing a session's evidence is worse than reading it twice, provided the
  # quote-level check above holds.
  log "ERROR: the reflect pass failed or timed out — state left unchanged, will retry"
  exit 1
fi
