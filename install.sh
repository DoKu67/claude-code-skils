#!/usr/bin/env bash
# Front door for this repository.
#
#     ./install.sh              install everything
#     ./install.sh --uninstall  remove the timer and hooks
#     ./install.sh --check      report what is installed, change nothing
#
# Installs, per machine:
#   * a background timer that commits and pushes skill changes every 6 hours
#   * the hooks that let an editing session hold off that sync until it is done
#
# Deliberately NOT installed here: the daily reflect pass. It spends model
# tokens and stages rules without being asked, so it is opt-in per machine —
#     ./scripts/install-reflect.sh
# --check reports it and --uninstall removes it either way, because a timer the
# documented uninstall leaves running is a trap.
#
# The skills themselves need no installation — Claude Code reads them from
# ~/.claude/skills the moment they are on disk.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-install}"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
say()   { printf '  %s\n' "$*"; }
warn()  { printf '  ! %s\n' "$*"; }
fail()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

bold "Claude Code skills — install"
echo

# ------------------------------------------------------------ prerequisites --

command -v git  >/dev/null 2>&1 || fail "git is required"
git -C "$HERE" rev-parse --git-dir >/dev/null 2>&1 || fail "$HERE is not a git checkout. Clone the repository first."

case "$(uname -s)" in
  Linux|Darwin) ;;
  *) fail "unsupported platform: $(uname -s). Supported: Linux (systemd), macOS (launchd)." ;;
esac

# --------------------------------------------------------------- where am I --
#
# Claude Code reads skills from ~/.claude and nowhere else. The scripts here all
# resolve their own paths, so they run correctly from any directory — but a
# checkout somewhere else means Claude never loads the skills, which is a
# confusing way to discover the problem later.

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
if [ "$HERE" != "$(cd "$CLAUDE_DIR" 2>/dev/null && pwd)" ]; then
  warn "This checkout is at:  ${HERE}"
  warn "Claude Code reads:    ${CLAUDE_DIR}"
  warn ""
  warn "The sync will work from here, but Claude will not load these skills."
  warn "Either clone into ${CLAUDE_DIR}, or symlink the directories you want:"
  warn "    ln -s ${HERE}/skills ${CLAUDE_DIR}/skills"
  echo
  printf '  Continue anyway? [y/N] '
  read -r reply </dev/tty 2>/dev/null || reply="n"
  case "$reply" in [yY]*) ;; *) echo "  Stopped."; exit 0 ;; esac
  echo
fi

# ------------------------------------------------------------------- check ---

if [ "$MODE" = "--check" ]; then
  bold "Status"
  case "$(uname -s)" in
    Linux)
      if systemctl --user is-enabled claude-skills-sync.timer >/dev/null 2>&1; then
        say "sync:    enabled"
        systemctl --user list-timers claude-skills-sync.timer --no-pager 2>/dev/null | sed -n '2p' | sed 's/^/    /'
      else
        say "sync:    not installed"
      fi
      if systemctl --user is-enabled claude-reflect.timer >/dev/null 2>&1; then
        say "reflect: enabled"
        systemctl --user list-timers claude-reflect.timer --no-pager 2>/dev/null | sed -n '2p' | sed 's/^/    /'
      else
        say "reflect: not installed (opt in with ./scripts/install-reflect.sh)"
      fi
      say "linger:  $(loginctl show-user "$USER" -p Linger --value 2>/dev/null || echo unknown)"
      ;;
    Darwin)
      launchctl list 2>/dev/null | grep -q claude-skills-sync \
        && say "sync:    loaded" || say "sync:    not installed"
      launchctl list 2>/dev/null | grep -q claude-reflect \
        && say "reflect: loaded" || say "reflect: not installed (opt in with ./scripts/install-reflect.sh)"
      ;;
  esac
  "${HERE}/scripts/install-hooks.sh" --dry-run 2>/dev/null | sed 's/^/  /'
  echo
  say "remote:  $(git -C "$HERE" remote get-url origin 2>/dev/null || echo 'none')"
  say "branch:  $(git -C "$HERE" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  exit 0
fi

# --------------------------------------------------------------- uninstall ---

if [ "$MODE" = "--uninstall" ]; then
  bold "Uninstalling"
  [ -x "${HERE}/scripts/install-sync.sh" ] && "${HERE}/scripts/install-sync.sh" --uninstall
  # Removed even though it is not installed here — otherwise the documented
  # uninstall leaves a timer that invokes claude every night.
  [ -x "${HERE}/scripts/install-reflect.sh" ] && "${HERE}/scripts/install-reflect.sh" --uninstall
  # Clear hook registration by emptying the merge source, then re-merging.
  if command -v python3 >/dev/null 2>&1 && [ -f "${HERE}/hooks/hooks.json" ]; then
    say "leaving hooks/hooks.json alone; to unregister the hooks run:"
    say "    python3 -c \"import json;p='${CLAUDE_DIR}/settings.json';d=json.load(open(p));d.pop('hooks',None);json.dump(d,open(p,'w'),indent=2)\""
  fi
  echo
  say "The skills themselves were not touched — this repository is still on disk."
  exit 0
fi

# ----------------------------------------------------------------- install ---

# Anyone other than the original author needs their own remote, or the sync will
# commit happily and fail at the push forever.
REMOTE="$(git -C "$HERE" remote get-url origin 2>/dev/null)"
case "$REMOTE" in
  *DoKu88/claude-code-skils*)
    if ! git -C "$HERE" ls-remote --exit-code origin >/dev/null 2>&1; then
      warn "origin is the upstream repository and is not reachable with your credentials."
      warn "Fork it, then point this checkout at your fork:"
      warn "    git remote set-url origin git@github.com:<you>/claude-code-skils.git"
      echo
    fi
    ;;
esac

chmod +x "${HERE}/scripts/"*.sh "${HERE}/hooks/"*.sh 2>/dev/null

[ -x "${HERE}/scripts/install-sync.sh" ] || fail "scripts/install-sync.sh is missing"
"${HERE}/scripts/install-sync.sh" || fail "the sync installer failed"

echo
bold "Installed"
say "Skills load automatically — nothing else to do for those."
say "The sync runs every 6 hours, and at boot if a slot was missed."
say "Hooks are read at session start; restart Claude Code to activate them."
echo
say "Check status:  ./install.sh --check"
say "Remove:        ./install.sh --uninstall"
