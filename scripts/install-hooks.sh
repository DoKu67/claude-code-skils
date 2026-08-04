#!/usr/bin/env bash
# Merge the tracked hook registration (hooks/hooks.json) into ~/.claude/settings.json.
#
# settings.json is machine state and is not tracked by this repo, so the two
# halves of a hook — the script and its registration — are stored apart. This
# script joins them, and is what makes a hook survive being cloned to a new
# machine.
#
#     ~/.claude/scripts/install-hooks.sh            merge and report
#     ~/.claude/scripts/install-hooks.sh --dry-run  show the result, write nothing
#
# Idempotent. Backs settings.json up before its first change.

set -uo pipefail

CLAUDE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_JSON="${CLAUDE_HOME}/hooks/hooks.json"
SETTINGS="${CLAUDE_HOME}/settings.json"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

say()  { printf '  %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "$HOOKS_JSON" ] || fail "no hooks.json at ${HOOKS_JSON}"
command -v python3 >/dev/null 2>&1 || fail "python3 is required to merge JSON safely"

CLAUDE_HOME="$CLAUDE_HOME" HOOKS_JSON="$HOOKS_JSON" SETTINGS="$SETTINGS" DRY_RUN="$DRY_RUN" \
python3 - <<'PY'
import json, os, shutil, sys

home     = os.environ["CLAUDE_HOME"]
src_path = os.environ["HOOKS_JSON"]
dst_path = os.environ["SETTINGS"]
dry      = os.environ["DRY_RUN"] == "1"

def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr); sys.exit(1)

try:
    with open(src_path) as f:
        src = json.load(f)
except json.JSONDecodeError as e:
    die(f"hooks.json is not valid JSON: {e}")

# Keys starting with _ are documentation and disabled examples, never installed.
hooks = src.get("hooks", {})
if not isinstance(hooks, dict):
    die("the 'hooks' key in hooks.json must be an object")

# {{CLAUDE_HOME}} keeps the file portable across machines with different paths.
hooks = json.loads(json.dumps(hooks).replace("{{CLAUDE_HOME}}", home))

try:
    with open(dst_path) as f:
        settings = json.load(f)
except FileNotFoundError:
    settings = {}
except json.JSONDecodeError as e:
    die(f"settings.json is not valid JSON, refusing to touch it: {e}")

current = settings.get("hooks", {})

if current == hooks:
    n = sum(len(v) for v in hooks.values()) if hooks else 0
    print(f"  settings.json already matches hooks.json ({n} registration(s), no change)")
    sys.exit(0)

if dry:
    print("  --dry-run, writing nothing. Would set settings.json 'hooks' to:")
    print("\n".join("    " + l for l in json.dumps(hooks, indent=2).splitlines()))
    sys.exit(0)

# Back up before the first modification so a bad merge is always recoverable.
backup = dst_path + ".pre-hooks.bak"
if os.path.exists(dst_path) and not os.path.exists(backup):
    shutil.copy2(dst_path, backup)
    print(f"  backed up settings.json -> {os.path.basename(backup)}")

if current and current != hooks:
    print("  NOTE: settings.json had hook registrations not in hooks.json.")
    print("        They are being replaced. The backup above has the originals;")
    print("        copy anything you want to keep into hooks/hooks.json.")

if hooks:
    settings["hooks"] = hooks
else:
    settings.pop("hooks", None)

# Write via a temp file so an interrupted write cannot truncate settings.json.
tmp = dst_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
os.replace(tmp, dst_path)

if hooks:
    for event, entries in sorted(hooks.items()):
        for entry in entries:
            for h in entry.get("hooks", []):
                cmd = h.get("command", "?")
                matcher = entry.get("matcher")
                label = f"{event}[{matcher}]" if matcher else event
                print(f"  registered {label}: {cmd}")
else:
    print("  hooks.json registers nothing; removed the 'hooks' key from settings.json")
PY

status=$?
[ $status -ne 0 ] && exit $status

# A registered hook that is not executable fails silently at runtime.
for f in "${CLAUDE_HOME}"/hooks/*.sh; do
  [ -e "$f" ] || continue
  [ -x "$f" ] || { chmod +x "$f"; say "made executable: $(basename "$f")"; }
done

[ "$DRY_RUN" = 1 ] || say "hooks are read at session start — restart Claude Code to pick up changes"
