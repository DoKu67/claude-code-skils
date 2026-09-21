#!/usr/bin/env bash
# PostToolUse(Bash) — whenever a training run has just written metrics, check that the
# metrics mean what their names say.
#
# WHY THIS IS A HOOK AND NOT A RULE. On one project three metrics reached a log under a name
# implying something they were not measuring: a trainer emitting `grad_norm` where the
# vocabulary declared `train/grad_norm`; an x-axis metric that reached disk but never the
# dashboard; a metric whose name said post-filter while it scored the pre-filter batch. Every
# one was found by a human reading raw values. Rules covering exactly this already existed in
# two skills and fired in none of the three cases — the failure was never a missing rule, it
# was a check nobody ran. A hook runs whether or not anyone remembers.
#
# IT FIRES ON EVIDENCE, NOT ON THE COMMAND NAME. An earlier version matched `train.py`,
# `torchrun`, `accelerate launch` — a guess that misses `make train`, `python -m src.train`,
# `deepspeed`, and whatever the next project calls it. Instead this looks for a run directory
# whose metrics were written in the last few minutes, which is true however training was
# launched, including from a background job.
#
# IT IS NEVER SILENT ABOUT BEING UNABLE TO CHECK. A project with no verifier of its own gets
# the generic checks, and the report says which ran. "Nothing to check" and "could not check"
# must not look alike — a project that appears verified and is not is worse than no hook.

set -uo pipefail

cat >/dev/null   # drain stdin; this hook keys off the filesystem, not the command text

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
generic="$HOME/.claude/hooks/verify_metrics_generic.py"

# The ml_logging contract: every run owns a directory containing metrics.jsonl. Any project
# following it is covered without configuring anything.
#
# A plain read loop rather than `mapfile` — this machine's /usr/bin/env bash resolves to the
# stock macOS bash (3.2, pre-GPLv3), which has no `mapfile` (added in bash 4). Under `set -u`
# that failed silently into "problems on every command" instead of "nothing to check".
fresh=()
while IFS= read -r line; do
  fresh+=("$line")
done < <(find "$project_dir" -maxdepth 6 -name metrics.jsonl -newermt '-10 minutes' 2>/dev/null | head -20)
[ "${#fresh[@]}" -gt 0 ] || exit 0

verifier="$project_dir/scripts/verify_metrics.py"
if [ -x "$verifier" ]; then
  checker="scripts/verify_metrics.py (project-specific: knows the declared vocabulary)"
  output=$(cd "$project_dir" && "$verifier" --skip-wandb 2>&1) && exit 0
else
  checker="generic checks only — this project has no scripts/verify_metrics.py, so nothing verified that its DECLARED metrics arrived"
  output=$(python3 "$generic" "${fresh[@]}" 2>&1) && {
    # Nothing wrong, but the weaker checker ran. Say so once rather than implying full cover.
    jq -n --arg c "$checker" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: ("A training run just wrote metrics and was checked with " + $c + ". No problems found by those checks, but a project-specific verifier would also confirm that every declared metric actually arrived. Consider adding scripts/verify_metrics.py.")
      }
    }'
    exit 0
  }
fi

jq -n --arg out "$output" --arg c "$checker" '{
  systemMessage: "metric verification found problems in the run that just finished",
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("A training run just finished and its metrics did not check out (" + $c + "). A metric that is absent, constant, or duplicated under two names is measuring something other than what its name says — investigate before reading any result from this run.\n\n" + $out)
  }
}'
exit 0
